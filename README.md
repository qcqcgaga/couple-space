# 情侣共享空间（couple_space）

一款情侣专用的共享空间手机 App：两个人一起记录、一起查看双方的笔记/记录，
支持配图，**重笔记、轻日历**。数据不依赖服务器，两台设备在同 WiFi 下自动
发现连接，蓝牙 / 热点手动连接，点对点端到端加密同步，双方地位平等、
以最新操作为准。

- 平台：Android + iOS（Flutter）
- 文档：先读 [AGENTS.md](AGENTS.md)，细节见 [docs/](docs/)

## 当前阶段

M1（共享核心）进行中：笔记模型、字段级 LWW、传输抽象、drift 本地存储
（notes/images/tombstones/peers/sync_state/local_identity）、同步协议帧
编解码、X25519 + ChaCha20-Poly1305 加密通道、mDNS + TCP 局域网传输
（含纯 Dart mDNS 应答器）均已实现并有单测；双进程协议探针
（`tool/probe.dart`）已跑通。下一步：图片分块续传队列、同步引擎编排。

## 快速开始

```bash
flutter pub get
flutter test
flutter analyze
```

### 本机协议探针（探针 A，双进程 mDNS + TCP + 分帧）

```bash
# 终端 1
dart run tool/probe.dart server --id probe-server --name 探针服务器
# 终端 2
dart run tool/probe.dart client --find probe-server --name 探针客户端
```

Windows 上若 5353 被占用，两端都加 `--mdns-port 55353`。

### Windows 中文路径提示

项目实际位于 `D:\agent_project\情侣共享空间`，但 Flutter 分析服务器在含中文的
路径下会崩溃（`flutter test` 不受影响）。请通过目录联接
`D:\agent_project\couple-space` 进入工程运行 Flutter 命令；
git 与文件操作在两个路径下均可。
