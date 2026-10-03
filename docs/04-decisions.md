# 情侣共享空间 · 关键决策记录（ADR）

> 规则：任何改变架构/协议/需求的决策都追加一条，注明日期、背景、备选与后果。
> 状态：Proposed（提议）/ Accepted（已定稿）/ Superseded（被替代）。

## ADR-001 双平台采用 Flutter

- 日期：2026-10-01 | 状态：Accepted
- 背景：一方 Android、一方 iPhone，需双平台且自研传输层。
- 决策：Flutter（Dart），UI 与同步引擎共享一套代码。
- 备选：Kotlin Multiplatform（引擎共享但 UI 分叉/工具链重）、React Native。
- 后果：局域网传输可写成纯 Dart，双端同源码；iOS 构建仍需 macOS。

## ADR-002 传输层：Dart mDNS+TCP 覆盖局域网/热点，BLE 原生

- 日期：2026-10-01 | 状态：Accepted
- 背景：要求“同一套底层同步逻辑”适配 WiFi/蓝牙/热点。
- 决策：LanTransport（multicast_dns + dart:io TCP）同时服务同 WiFi 与热点；
  蓝牙用各平台原生 BLE，通过平台通道接入同一 `Transport` 抽象。
- 后果：大文件只走 TCP；BLE 定位为小数据通道；Android 需 MulticastLock。

## ADR-003 冲突策略：字段级 LWW + 墓碑

- 日期：2026-10-01 | 状态：Accepted
- 背景：双方平等，最新操作为准；避免删除被旧数据复活。
- 决策：每个字段独立 `(lwTs, lwDeviceId)` 决胜；删除作为字段写入；
  图片按图片ID 独立 LWW；墓碑保留 30 天后压缩。
- 备选：整条 LWW（更简单但体验差）。

## ADR-004 端到端加密与配对

- 日期：2026-10-01 | 状态：Accepted
- 决策：首次配对用二维码/配对码（作为 SAS）交换身份公钥；
  通道用 X25519 ECDH + ChaCha20-Poly1305 加密；自动连接仅限已配对白名单。
- 后果：实现复杂度略增，但本地网络传输不裸奔。

## ADR-005 本地存储：SQLite（drift）

- 日期：2026-10-01 | 状态：Accepted
- 决策：drift/SQLite 存笔记、图片元数据、墓碑、同步状态；图片文件入文件系统。
- 备选：Hive（键值快，但关系查询弱）。

## ADR-006 图片不限制大小，分块续传

- 日期：2026-10-01 | 状态：Accepted
- 背景：用户明确“完全不限制单张大小”。
- 决策：原图全量传输 + 本地缩略图 + 分块/断点续传/持久化队列。
- 后果：存储占用由用户自行管理；蓝牙通道不建议传大图。

## ADR-007 提醒用本地通知

- 日期：2026-10-01 | 状态：Accepted
- 决策：每设备本地排定系统通知；无服务器推送。
- 已知限制：对方设备的提醒依赖同步成功；iOS/Android 后台限制意味着
  自动连接主要发生在 App 前台。此限制写入需求文档。

## ADR-008 备份为手动文件导出/导入

- 日期：2026-10-01 | 状态：Accepted
- 决策：导出 zip（JSON + 图片）；导入按 LWW 合并，图片按 sha256 去重。

## ADR-009 iOS 构建与安装：无 Mac 的云端 CI 路线

- 日期：2026-10-01 | 状态：Accepted
- 背景：用户无 Mac，确认不存在免费的本机 macOS 构建环境。
- 决策：日常在 Windows 开发共享 Dart 逻辑与 Android；iOS 构建走云端 macOS CI：
  **仓库确认开源，GitHub Actions macOS runner 为主路线**（公开仓库标准 runner
  免费），Codemagic 免费档（约 500 分钟/月）为私有化备选；真机安装用免费
  Apple ID 通过 Sideloadly/AltStore 签名安装（7 天重签）。
- 后果：无法本机跑 iOS 模拟器；iOS 构建按需、低频；长期稳定签名可选
  $99/年 开发者账号 + Ad Hoc 分发（免上架、一年一续），或 TestFlight
  （90 天重传）；免费 Apple ID 为 7 天重签方案（另行决策）。

## ADR-010 配对白名单与自动连接边界

- 日期：2026-10-01 | 状态：Accepted
- 决策：自动发现只自动连接已配对设备；陌生设备不自动连接；
  提供手动兜底（输入 IP/配对码）。

## ADR-011 时钟策略（v1 用设备时钟）

- 日期：2026-10-01 | 状态：Accepted
- 决策：v1 用设备时钟 + 设备ID 决胜；若出现时钟回拨导致异常，
  升级为混合逻辑时钟（HLC），记录为 Superseded。

## ADR-012 产品形态：重笔记、轻日历

- 日期：2026-10-01 | 状态：Accepted
- 背景：用户明确产品不应像纯日历待办，核心价值是“一起记录”，日历只是辅助。
- 决策：核心实体定义为「笔记/记录」，正文为主、标题可选；时间为可选属性
  （不绑定 / 全天 / 时间段）；提醒仅对有绑定时间的笔记提供；笔记列表是主视图，
  日历只展示绑定时间的记录。
- 后果：原“计划（plans）”概念整体替换为“笔记（notes）”，同步协议与 LWW
  设计不变，仅实体与字段重命名；UI 默认进入笔记列表而非日历。

## ADR-013 同步协议帧线格式（v1 定稿）

- 日期：2026-10-01 | 状态：Accepted
- 背景：docs/02 §4.3 只定了帧类型清单，M1 需要可实现的线格式。
- 决策：
  - 帧 = `[4 字节大端载荷长度][1 字节帧类型][载荷]`；除 ImageChunk 外载荷为
    JSON（UTF-8），便于调试与扩展。
  - ImageChunk 载荷为 `[4 字节 meta 长度][meta JSON（imageId/seq/total/size）]
    [原始数据块]`，避免 base64 膨胀。
  - 加密通道在协议帧外再包一层密文帧：
    `[4 字节长度][nonce(12)+cipherText+MAC(16)]`，每条消息独立随机 nonce，
    “加密并认证整帧”。
- 后果：TCP/BLE 共用同一帧格式；帧上限 64 MB（覆盖大图分块场景）。

## ADR-014 mDNS 服务注册采用纯 Dart 应答器

- 日期：2026-10-01 | 状态：Accepted
- 背景：ADR-002 选定 multicast_dns，但该包只支持发现（查询），不支持注册
  Bonjour 服务（源码中有 TODO）。
- 决策：自研最小 mDNS 应答器（`MdnsResponder`，纯 Dart）：监听
  224.0.0.251:5353，回应 PTR/SRV/TXT/A 查询并周期性主动宣告；
  发现仍用 multicast_dns。
- 后果：双端同源码、Windows 可单测；应答只覆盖本项目需要的记录类型。

## ADR-015 Windows 单机 mDNS 联测经验与对策

- 日期：2026-10-01 | 状态：Accepted
- 背景：Windows 上 5353 可能被其它应用占用；多网卡（含虚拟/隧道网卡）导致
  multicast_dns 启动失败；组播发送会异步触发 errno 1232 socket 错误；
  单播 mDNS 应答在本机回环下不可靠。
- 决策：
  - `LanTransport` 增加 `mdnsPort` 参数（默认 5353），测试/调试可换端口。
  - mDNS 客户端与应答器都只加入一个首选网卡（非回环、非 link-local 优先），
    跳过 join 失败的网卡。
  - 应答用组播发送（查询方已加入组播组即可收到），并给 socket 流挂
    `onError` 吞掉 Windows 的 1232 异步噪声。
- 后果：Windows 单机可稳定跑双进程/双端 mDNS 测试；真实局域网仍走标准 5353。

## ADR-016 会话密钥派生与存储表补充

- 日期：2026-10-01 | 状态：Accepted
- 决策：
  - 会话密钥与配对码用 HKDF-SHA256 从 X25519 共享密钥派生；info 绑定双方
    公钥时先按字节排序，保证双方各自计算得到相同结果。
  - images 表补充 `lwTs/lwDevice/totalChunks`（图片级 LWW 与续传需要）；
    新增 `local_identity` 表保存本机设备 ID 与身份密钥对（base64）。
- 后果：docs/02 §7 表草案在实现时做了字段补充，均为实现细节，不改变架构。

## ADR-017 同步引擎连接封装与明文→密文升级

- 日期：2026-10-01 | 状态：Accepted
- 背景：docs/02 §4.1 要求“先明文握手、再协商会话密钥、随后全程加密”，但
  dart:io Socket 是单订阅流，不能“明文、密文各监听一次”。
- 决策：
  - 引擎侧用 `SyncConnection` 统一消费底层字节：握手阶段解明文协议帧；
    收到对端最终 Ack 时同步标记 `finishHandshake()`，同一数据块中握手帧
    之后的剩余字节按密文暂存；会话密钥派生完成后 `upgrade()` 建立加密通道
    并冲刷暂存密文。
  - 升级前先把会话阶段切到 sync：`upgrade()` 冲刷密文时会解码出对端已
    加密的 VersionMap，必须按同步阶段派发，否则帧会被握手分发器忽略。
  - 连接层发送串行化：驱动协程与帧处理器可能并发发送（VersionMap 与
    NoteDelta），Windows 下 Socket.flush() 并发会报 “StreamSink is bound
    to a stream”。
- 后果：TCP/BLE 同一套握手与升级逻辑；真实 TCP 下可稳定跑双进程同步。

## ADR-018 VersionMap 差异策略：摘要不同即双向推送完整记录

- 日期：2026-10-01 | 状态：Accepted
- 背景：docs/02 §4.2 写“向对方请求缺失或更新的记录”。但字段级 LWW 下，
  单条记录的摘要（最大字段版本）较旧的一方可能仍持有较新的字段写入；
  若只按“较新摘要单向拉取”，这些字段更新会被漏掉。
- 决策：VersionMap 比对以“摘要不同（ts / deviceId / deleted 任一不同）
  即双向推送完整记录（携带全字段版本）”为准；接收方仍按字段级 LWW 合并。
- 后果：对家庭场景的小数据量完全够用；协议不新增 Request 帧，实现与
  docs/02 的帧清单保持一致。

## ADR-019 图片传输队列持久化与续传语义

- 日期：2026-10-01 | 状态：Accepted
- 背景：docs/02 §4.4/§7 要求传输队列持久化、按已收块位图续传。
- 决策：
  - 新增 `image_transfers` 表（peerId+imageId 主键）：保存发送意图、分块
    配置、已发块位图与错误信息，App 重启不丢。
  - `images` 表补充 `chunkSize` 列：接收方写文件与续传定位必须知道块大小，
    与发送方不一致时重置位图整图重传。
  - 续传以“接收方 images.chunkBitmap”为权威：发送方只补发接收方位图缺失的
    块；发送方 sentBitmap 仅作进度展示。本地图片不完整时无条件推送
    ImageMeta（携带本地位图），触发对端补发，覆盖“摘要相同但文件残缺”的
    重连场景。
  - 收齐全部块后校验 sha256；失败则标记 failed 并整图重传。
  - `ImageMeta.copyWith` 的 `?? this.xxx` 模式无法置空字段，合并不再使用
    copyWith 清位图，改为直接构造新对象。
- 后果：图片与笔记独立同步；传输中断/重启后从缺失块继续，不重复传输。

## ADR-020 同步存储端口：SyncStorage（drift + 内存实现）

- 日期：2026-10-01 | 状态：Accepted
- 背景：双进程探针需要真实引擎跑完整同步，但 `dart run` 并发进程会争抢
  `.dart_tool/lib/sqlite3.dll`（Windows 文件锁），且 AOT 无法内嵌 sqlite3
  原生资产。
- 决策：引擎不直接依赖 drift DAO，改为依赖 `SyncStorage` 端口：
  - `DriftSyncStorage`：生产实现，复用既有 DAO 与 NoteStore（LWW+墓碑），
    零逻辑重复；
  - `MemorySyncStorage`：纯内存实现，供双进程探针/单元测试，进程不加载
    sqlite3，彻底规避原生资产冲突。
- 后果：探针进程可用纯 Dart 跑完整引擎（mDNS + TCP + 加密 + 分块传输）；
  引擎测试仍覆盖 drift 生产存储路径。

## ADR-021 协议帧补充：Auth.paired、RecordVersion.kind、ImagePayload 进度

- 日期：2026-10-01 | 状态：Accepted
- 决策（均为向后兼容的附加字段，默认值与旧实现一致）：
  - `AuthFrame.paired`：告知对端本机白名单中是否有该设备；任一方未配对即
    进入配对流程，避免“一端已配对、另一端丢白名单”时握手死锁。
  - `RecordVersion.kind`（note/image）：VersionMap 区分笔记与图片摘要。
  - `ImagePayload.syncStatus/totalChunks/chunkSize/chunkBitmap`：ImageMeta
    携带发送方本地传输进度，支撑续传握手。
- 后果：docs/02 §4.3 帧清单不变，仅字段扩充。

## ADR-022 双进程同步探针（sync-server / sync-client）

- 日期：2026-10-01 | 状态：Accepted
- 决策：扩展 `tool/probe.dart`：`sync-server`/`sync-client` 模式用真实
  mDNS + TCP 建立连接，两端各自运行完整 `SyncEngine`（配对、加密、笔记与
  图片分块同步），并接入 `flutter test`（`test/transports/
  two_process_sync_test.dart`）。
- 后果：Windows 本机可自动化验证“发现→握手→加密→增量→图片断点续传”
  全链路；探针输出使用串行化写队列避免 Windows 重定向下 stdout 竞态。

## ADR-023 M2 UI 分层：app / services / platform

- 日期：2026-10-02 | 状态：Accepted
- 背景：docs/02 §11 建议的目录结构落地到 M2（Flutter UI + 用例层）。
- 决策：
  - `lib/app/` 放 UI（主题、主页骨架、笔记列表/日历/当日记录/编辑页、卡片、
    月历、空态插画等组件）；`lib/services/` 放用例层（NoteService、
    AppServices 装配）；`lib/platform/` 放平台插件抽象（ImagePickerBridge）。
  - 用例层不直接依赖页面：NoteService 提供 CRUD、图片管理、按日查询、
    缩略图；页面只消费 NoteService。
  - 响应式数据流：NotesDao 增加 `watchNotes()`——同时监听 notes /
    note_field_versions / images 三张表，任一变化即重查并发出最新列表，
    供列表与日历两个主视图消费；卡片缩略图按需生成。
- 后果：M3 接入同步引擎时复用同一 NoteService 与 DriftSyncStorage，
  页面无需感知协议细节。

## ADR-024 缩略图缓存策略

- 日期：2026-10-02 | 状态：Accepted
- 背景：docs/01 §6.3 要求“本地自动生成缩略图用于列表/日历展示；原图完整保留”。
- 决策：
  - 新增 `ThumbnailStore`（应用 cache 目录 `thumbnails/`）：用 `image` 包
    从原图生成最长边 480px 的 JPEG（质量 82），文件名为 `<imageId>_thumb.jpg`，
    缺图/无法解码时返回 null 由 UI 显示占位。
  - 原图不压缩、不改写（ADR-006 的不限制大小约束不变）；缩略图按需生成并
    缓存，图片删除时一并清理。
- 后果：列表/日历滚动只读小图；大图文件仍只在需要时读取。

## ADR-025 编辑保存：仅对变化的字段重新打时间戳

- 日期：2026-10-02 | 状态：Accepted
- 背景：字段级 LWW 要求“每个字段独立决胜”；若整张表单保存时把所有字段都
  重新打上本机时间戳，会把对方更新的“未改动字段”错误覆盖。
- 决策：`NoteService.updateNote` 逐字段比较当前值与草稿，只对真正变化的
  字段写 `FieldVersion(now, deviceId)`；未变化字段保留原有版本。
- 后果：两人同时编辑不同字段时各自保留（符合 ADR-003）；实现上直接构造新
  Note 而非 copyWith，避免 copyWith 无法把 reminderAt 置空的问题
  （与 ADR-019 对图片的处理同源）。

## ADR-026 列表排序、日历日期归属与提醒基准时间

- 日期：2026-10-02 | 状态：Accepted
- 决策：
  - 笔记列表按「最后写入时间（fieldVersions 最大值）倒序」，退化为创建时间；
    不绑定时间的笔记正常显示。
  - 日历日期归属：全天只覆盖 startAt 当天；时间段覆盖 startAt～endAt 的
    日期闭区间；起点缺失按不绑定处理，终点缺省视为起点当天；不绑定的记录
    不进入日历。
  - 提醒基准（v1）：全天以当天 09:00 为基准（避免午夜提醒），时间段以
    startAt 为基准；`reminderAt = 基准 - 提前分钟数`；M2 只录入与存储字段，
    实际通知调度在 M5 接入 flutter_local_notifications。
- 后果：列表与日历行为可单测（NoteService.coversDay / daysWithNotesInMonth /
  reminderAtFor）；M5 通知调度直接读 reminderAt。

## ADR-027 图片导入端口：LocalImageImporter

- 日期：2026-10-02 | 状态：Accepted
- 背景：组件测试在 flutter_test 的假异步环境下做真实文件 IO 会挂起，
  且测试不应依赖磁盘。
- 决策：NoteService 依赖 `LocalImageImporter` 端口导入本地图片
  （复制原图 + 生成缩略图 + 计算 sha256/size）；生产用
  `DiskLocalImageImporter`，测试注入 `MemoryLocalImageImporter`（不碰磁盘）。
- 后果：用例层与 UI 测试完全脱离磁盘；真实文件行为仍由服务层单测
  （plain test，真实事件循环）覆盖。

## ADR-028 Windows 组播回环能力探测与 mDNS 测试自动跳过

- 日期：2026-10-02 | 状态：Accepted
- 背景：本机在 2026-10-02 出现组播回环退化：两个进程各自绑定同一 UDP 端口
  （mDNS 单机测试的必要形态）时，Windows 只把组播包投递给其中一个 socket，
  进一步排查发现原始组播回环仍可用，但完整 mDNS 栈（应答器 + multicast_dns
  客户端）在本机失效，导致 `lan_transport_test` 的 mDNS 发现与两个双进程
  探针超时失败；此前同一环境（66 项）全过。真实局域网/真机各自绑定端口，
  不受此问题影响。
- 决策：
  - 新增 `test/transports/mdns_capability.dart`：在进程内启动真实的
    `MdnsResponder` 与 `multicast_dns` 客户端（使用与 LanTransport 相同的
    首选网卡选择逻辑），验证“服务宣告 + PTR 查询应答”的完整 mDNS 栈是否
    成立；不成立时相关 mDNS 用例（LanTransport mDNS 发现、双进程 probe、
    双进程 sync）自动跳过并给出原因。三个测试文件各自使用独立端口
    （55353/55354/55355 与探测端口 55363/55364/55365），避免并行抢占。
  - 保留 `tool/multicast_probe.dart` 作为人工诊断工具
    （listener/sender/bind/send）。
- 后果：`flutter test` 在 mDNS 栈不可用的 Windows 上保持通过（相关用例
  skip，其余全跑）；在健康的单机/CI 环境仍会真实执行 mDNS 全链路验证。

## ADR-029 M3 应用层同步编排：SyncService + 白名单自动连接

- 日期：2026-10-03 | 状态：Accepted
- 背景：M1 的同步引擎（SyncEngine）与 M2 的 App（NoteService/AppServices）
  已完成，但引擎尚未接入 App；需要“发现→自动连接→配对→增量同步”的
  应用层编排与 UI。
- 决策：
  - 新增 `SyncService`（ChangeNotifier，lib/services/sync_service.dart）：
    装配 LanTransport + SyncEngine + DriftSyncStorage，复用 AppServices 的
    identity / imageFiles；启动时加载设备昵称与自动连接开关
    （sync_state 键值 `device_name` / `auto_connect`），并请求运行时权限、
    获取 MulticastLock。
  - 发现策略与 docs/02 §5 一致：mDNS 发现的设备只有「已在 peers 白名单」
    或「二维码已锁定身份」才自动连接；陌生设备仅展示，用户手动发起配对。
  - 会话去重：握手识别出对端设备 ID（`SyncSession.peerKnown`）后，每端
    对同一 peer 只保留一个活跃会话；双向同时发起连接产生的重复会话直接
    关闭新会话（LWW 幂等兜底，数据不会错乱）。
  - App 装配：`AppServices.open()` 创建并启动 SyncService；`close()` 停止；
    HomeShell 新增「同步」页签（本机信息、二维码/配对码、设备与白名单、
    手动 IP 直连、蓝牙/热点入口、最近同步事件）。
- 后果：M1 引擎无需改动协议即可被 UI 消费；页面只面向 SyncService 状态，
  协议细节仍隔离在 core/sync。

## ADR-030 二维码配对：pair URI + 引擎锁定身份公钥 + SAS 确认

- 日期：2026-10-03 | 状态：Accepted
- 背景：docs/02 §5 要求“首次配对用二维码/配对码建立信任、交换身份公钥”；
  引擎已有 6 位 SAS（配对码）确认流程，但没有二维码通道。
- 决策：
  - 二维码内容为 `couple-space://pair?deviceId=...&name=...&key=...`
    （`PairQrCodec`，lib/core/pairing/qr_codec.dart），key 为 X25519 身份
    公钥 base64；本机二维码用 qr_flutter 渲染，扫码/粘贴内容后锁定对端。
  - 引擎新增 `SyncEngine.prepareQrPairing(deviceId, identityPublicKey)`：
    配对时校验对端 Hello 携带的公钥与二维码一致，不一致直接
    identity_mismatch 失败；一致仍照常弹出 6 位配对码让用户确认
    （SAS 仍是会话级防中间人手段，二维码不替代码确认，只是 out-of-band
    锁定身份，PairingChallenge 增加 `verifiedByQr` 标记供 UI 提示）。
  - 摄像头扫码留待真机联调（与蓝牙同批）；当前提供“复制二维码内容 +
    粘贴输入”的完整可测路径。
- 后果：配对码与二维码均可完成首次配对；二维码流程不削弱 SAS 防中间人
  语义，代价是扫码仍需一次码确认（两边显示一致，UI 提供自动填入）。

## ADR-031 Android 权限与平台通道：MulticastLock / 运行时权限 / 蓝牙预留

- 日期：2026-10-03 | 状态：Accepted
- 背景：docs/02 §6 要求补齐 Android 权限（NEARBY_WIFI_DEVICES、位置、
  蓝牙、通知），mDNS 需要 MulticastLock；蓝牙原生 BLE 按 §3.3 预留。
- 决策：
  - AndroidManifest 补齐：INTERNET/ACCESS_NETWORK_STATE/ACCESS_WIFI_STATE/
    CHANGE_WIFI_MULTICAST_STATE、NEARBY_WIFI_DEVICES（neverForLocation）、
    位置权限（maxSdkVersion=32）、蓝牙细粒度权限（SCAN/CONNECT/ADVERTISE）
    与旧版 BLUETOOTH/ADMIN、POST_NOTIFICATIONS（M5 提醒先声明）、BLE 特性
    非必需声明。
  - MainActivity 实现三个平台通道：`couple_space/wifi`（WifiManager
    MulticastLock）、`couple_space/permissions`（ActivityCompat 按当前 SDK
    过滤并请求运行时权限，返回被授予项）、`couple_space/bluetooth`
    （BLE 契约占位，当前统一返回 not_implemented，真机联调时实现）。
  - Dart 侧封装：`MethodChannelMulticastLock`（非 Android 静默）、
    `ChannelPermissionRequester`、`BluetoothChannel` 接口 +
    `BluetoothPlatform` 实现（扫描/发现/连接/字节流契约，原生未实现时
    上层提示“待真机联调”）。
  - iOS 侧代码预留：Info.plist 增加 NSLocalNetworkUsageDescription、
    NSBonjourServices（_couple-space._tcp）、NSBluetooth 说明；构建仍走
    GitHub Actions macOS runner（ADR-009）。
- 后果：Android 权限与组播锁在真机上可用；蓝牙/扫码等原生能力保持同一
  契约，接入时不改上层。

## ADR-032 Transport 手动直连接口与会话去重语义

- 日期：2026-10-03 | 状态：Accepted
- 背景：docs/02 §3.2 的“手动兜底：输入 IP 直连（跳过发现）”此前只在
  LanTransport 内部存在，未进入 Transport 抽象；App 层手动连接需要通用入口。
- 决策：
  - `Transport` 接口增加 `connectToHost(host, port)`：LanTransport 实现为
    TCP 直连；蓝牙等通道不支持时抛 UnsupportedError；测试假传输按相同
    语义实现。
  - 同步服务层对同一 peer 的会话去重以「握手识别出的对端设备 ID」为准
    （`SyncSession.peerKnown` 完成即注册），不依赖发起/接受方向；重复会话
    由后建立方关闭，SyncEngine 本身保持多会话能力不变。
- 后果：手动 IP 直连与自动发现共用同一 TCP 通道与握手逻辑；未来接入蓝牙
  Transport 时无需改 SyncService 的连接编排。
