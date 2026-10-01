# 情侣共享空间 · 技术实现方案

- 版本：v1.0（基线）
- 定稿日期：2026-10-01
- 状态：已定稿，开发按本文档执行；偏离需记录到 docs/04-decisions.md

## 1. 技术选型总览

| 层 | 选型 | 理由 |
| --- | --- | --- |
| 应用框架 | Flutter（Dart） | Android/iOS 共用 UI 与业务逻辑，一套代码 |
| 同步引擎 | Dart 实现（共享） | 核心逻辑双端一致、可在 Windows 直接单测 |
| 局域网/热点传输 | Dart：multicast_dns + dart:io TCP | 双端同源码，天然满足“同一套底层逻辑” |
| 蓝牙传输 | 原生 BLE（平台通道接入） | Android/iOS 蓝牙栈不同，必须原生实现 |
| 本地存储 | SQLite（drift） | 关系模型适合笔记/图片/同步元数据 |
| 图片文件 | 应用文档目录 + 缩略图缓存目录 | 大图不进数据库 |
| 加密 | X25519 + ChaCha20-Poly1305（Dart cryptography） | 端到端加密、实现简单 |
| 本地通知 | flutter_local_notifications / 平台通道 | 双端本地通知 |

## 2. 架构分层

```
UI（Flutter 页面）
  └─ Application/Service（笔记用例、提醒调度、备份、配对）
       └─ SyncEngine（同步核心：版本比较、增量合并、图片队列）
            └─ Transport（传输抽象）
                 ├─ LanTransport（Dart：mDNS + TCP，覆盖 WiFi/热点）
                 └─ BluetoothTransport（原生 BLE，平台通道）
  └─ DataStore（drift/SQLite + 文件系统）
  └─ Crypto（密钥、加密通道）
```

- 传输层只提供“可靠字节流 + 发现事件”，同步引擎不关心底层是什么连接。
- 蓝牙与局域网在引擎层面共用同一套协议帧与合并逻辑。

## 3. 传输层设计

### 3.1 抽象接口

```dart
abstract class Transport {
  TransportKind get kind; // lan | bluetooth | hotspot(复用lan)
  Stream<PeerDiscovered> get onPeerDiscovered;
  Stream<Connection> get onIncoming;
  Future<void> startDiscovery();
  Future<void> stopDiscovery();
  Future<Connection> connect(PeerId peer);
}

abstract class Connection {
  Stream<Uint8List> get incoming;
  Future<void> send(Uint8List bytes);
  Future<void> close();
}
```

### 3.2 局域网 / 热点（LanTransport，Dart 共享实现）

- 发现：mDNS，服务类型建议 `_couple-space._tcp`（应用内自定，注册 Bonjour 服务）。
- 连接：TCP socket；应用层分帧（长度前缀 + 帧类型 + 载荷）。
- 热点场景复用：一方开热点、另一方加入后，两者处于同一局域网，直接用 LanTransport。
- Android 注意：扫描/组播需要 `WifiManager.MulticastLock`，否则收不到 mDNS 响应。
- 手动兜底：输入对端 IP 直连（跳过发现，仍走同一 TCP 通道）。

### 3.3 蓝牙（BluetoothTransport，双端原生实现）

- 采用 BLE GATT 自定义服务，双方互为主/从或由发起方当 central。
- 受 MTU 限制分块传输；自动协商 MTU；适合小数据。
- 大图不推荐走蓝牙（速度慢、耗电），UI 上可提示改用 WiFi/热点。
- iOS 后台蓝牙有限制：仅支持特定后台模式，不作为长连接方案。

### 3.4 传输优先级

同 WiFi/局域网 > 热点 > 蓝牙。大文件（图片）只走 TCP 通道（WiFi/热点）。

## 4. 同步协议

### 4.1 连接与握手

1. 发现（或手动触发）→ 建立 TCP/BLE 通道。
2. Hello：设备ID、App 版本、协议版本。
3. 身份认证：交换/核对身份公钥；未配对则进入配对流程（见 §5）。
4. 协商会话密钥（ECDH）→ 建立加密通道。

### 4.2 增量同步流程

1. 双方交换“记录版本摘要”：每条笔记/图片的 (recordId, updatedAt, deviceId, deleted)。
2. 各自比对，向对方请求缺失或更新的记录（含字段级 last-write 元数据）。
3. 应用方按字段级 LWW 合并写入本地。
4. 完成后交换 Ack；本地记录最后同步向量，供下次增量使用。

### 4.3 消息帧草案

| 帧类型 | 内容 |
| --- | --- |
| Hello / PeerInfo | 设备ID、公钥、协议版本 |
| Auth / Pair | 配对码验证、SAS 校验 |
| VersionMap | 记录版本摘要 |
| NoteDelta | 笔记创建/更新/删除（字段 last-write） |
| ImageMeta | 图片元数据（ID、大小、sha256） |
| ImageChunk | 序号、总数、数据块（支持续传） |
| Ack / Error | 确认与错误 |

### 4.4 图片续传

- 每张图片记录已收块序号位图；断线重连后从缺失块继续。
- 传输队列持久化到本地（drift 表），App 重启不丢。

## 5. 配对与安全

- 首次配对：一方向另一方出示二维码（或口头输入 6 位配对码），
  双方各自生成身份密钥对，交换公钥；配对码作为 SAS（短认证串）验证，
  防止中间人。
- 通道加密：每次连接 ECDH（X25519）协商会话密钥，ChaCha20-Poly1305 加密载荷。
- 已配对设备存入白名单（peers 表）；自动连接只查白名单。
- 解绑：任一设备可解除配对（可选功能，v1 至少支持清除对方白名单）。

## 6. 平台实现要点与已知限制

### Android

- 权限：`NEARBY_WIFI_DEVICES`（Android 13+）、旧版本位置权限（扫描）、
  `BLUETOOTH_SCAN/CONNECT`、`POST_NOTIFICATIONS`。
- 热点创建：Android 13+ 使用 `TetheringManager`，系统弹窗授权。
- mDNS 需要 MulticastLock；App 退到后台后扫描/监听受限。

### iOS

- Info.plist：`NSLocalNetworkUsageDescription` + Bonjour services 声明；
  `NSBluetoothAlwaysUsageDescription`；通知权限。
- iPhone **不能由 App 程序化开启热点**：热点方向固定为
  “Android 开热点 → iPhone 手动加入”，或 iPhone 手动开个人热点后 Android 加入。
- 后台限制：iOS 不保证后台常驻网络连接，同 WiFi 自动发现主要依赖
  App 在前台/短暂后台窗口；蓝牙后台模式有限。

### 双端一致的现实约束（写入需求，避免误解）

- “自动连接” = App 运行（前台为主）时的自动发现与连接，不是系统级常驻服务。
- 提醒在对方设备上必须等一次成功同步后才能排定。
- 大文件同步建议保持 App 前台、双端处于同一网络。

## 7. 数据模型（库表草案）

> 核心实体为「笔记（记录）」，时间为**可选属性**：不绑定时间 / 全天 / 时间段。
> 无时间绑定的记录只出现在笔记列表，不进入日历。

### notes（笔记主表）

| 列 | 类型 | 说明 |
| --- | --- | --- |
| id | TEXT | UUID |
| title | TEXT | 可选；缺省可由正文首行生成展示 |
| content | TEXT | 正文主体 |
| timeBind | TEXT | none / allDay / range，默认 none |
| startAt / endAt | DATETIME | 绑定时间；allDay 时只记日期 |
| color / location / repeatRule | 常规 | repeatRule 预留 |
| reminderOffsetMin / reminderAt | INT/TEXT | 提醒设置，null=关闭（仅绑定时间时可用） |
| createdBy / createdAt | TEXT/INT | 创建方与时间 |
| deleted | BOOL | 墓碑标记 |
| deletedAt / deletedBy | INT/TEXT | 删除元数据（参与 LWW） |

### note_field_versions（字段级版本表）

| 列 | 说明 |
| --- | --- |
| noteId + field | 联合主键 |
| lwTs / lwDevice | 最后写入时间戳与设备ID |

### images（图片表）

| 列 | 说明 |
| --- | --- |
| id / noteId | 关联 |
| fileName / sha256 / size | 文件信息 |
| deleted / deletedAt / deletedBy | 墓碑 |
| syncStatus | pending/partial/done |
| chunkBitmap | 已收块位图（续传） |

### tombstones（墓碑表）

记录已删除记录及其删除时间；超过 30 天且双方已确认后压缩清理。

### peers / sync_state

- peers：对方设备ID、昵称、身份公钥、配对时间、最后连接时间。
- sync_state：本地设备ID、最后同步向量、待发送图片队列。

## 8. 冲突解决详细规则

1. 比较器：`(lwTs, lwDeviceId)`，数值大者胜。
2. 笔记各字段独立比较，落库时逐字段应用。
3. 删除按 deleted 字段参与比较；删除赢则整条进入墓碑，UI 隐藏。
4. 图片以图片ID 为粒度，添加/删除各自 LWW。
5. 时间戳使用设备时钟；若未来发现时钟回拨问题，升级混合逻辑时钟（HLC）
   （记录到 ADR，v1 用设备时钟 + 设备ID 决胜已足够）。

## 9. 提醒实现

- 笔记写入本地后，服务层重算该笔记的通知调度（新增/变更/删除/关闭）；
  仅绑定了时间的笔记参与调度。
- 同步收到对方创建的提醒 → 本地重新调度。
- 通知点击 → 打开笔记详情页（deep link / 路由参数）。
- 权限申请时机：用户第一次设置提醒时引导。

## 10. 备份实现

- 导出：zip = `export.json`（schemaVersion、notes、field versions、tombstones、
  peers 白名单）+ `images/`。通过系统分享保存。
- 导入：解析后按 LWW 合并写入；图片按 sha256 去重。
- 导入前提示将按“最新操作为准”合并，非覆盖。

## 11. 目录结构（建议）

```
lib/
  app/          # Flutter UI（日历、列表、详情、设置、配对）
  core/
    models/     # 领域模型
    storage/    # drift 表与 DAO
    crypto/     # 密钥、加密通道
    sync/
      engine.dart
      protocol/ # 帧定义、编解码
      transports/
        lan/          # mDNS + TCP（Dart）
        bluetooth/    # 平台通道封装
  services/     # 笔记用例、提醒调度、备份、配对
  platform/     # MethodChannel 封装（BLE、通知、热点等原生能力）
android/ ios/   # 原生工程
test/           # Dart 单测/集成测试
```

## 12. 里程碑

- **M1 共享核心**：drift 模型、字段级 LWW、加密通道、LanTransport（mDNS+TCP）、
  图片分块续传、Dart 单测/双进程协议测试（Windows 可跑）。
- **M2 Android App**：笔记 CRUD、笔记列表（主）+ 日历（辅助）UI、本地存储、图片选择与管理。
- **M3 配对与 Android 传输**：配对码/二维码、蓝牙、热点、Android 真机联调。
- **M4 iOS**：iOS 传输（mDNS+TCP 复用 Dart、BLE 原生）、iOS 构建与联调。
- **M5 完整闭环**：提醒、备份、双端真机全路径验收、UI 打磨（简约可爱）。
