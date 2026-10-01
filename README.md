# 情侣共享空间（couple_space）

一款情侣专用的共享空间手机 App：两个人一起记录、一起查看双方的笔记/记录，
支持配图，**重笔记、轻日历**。数据不依赖服务器，两台设备在同 WiFi 下自动
发现连接，蓝牙 / 热点手动连接，点对点端到端加密同步，双方地位平等、
以最新操作为准。

- 平台：Android + iOS（Flutter）
- 文档：先读 [AGENTS.md](AGENTS.md)，细节见 [docs/](docs/)

## 当前阶段

M1（共享核心）起步：笔记模型、字段级 LWW 冲突合并、传输层抽象接口已完成；
存储、同步协议、UI 尚未开始。

## 快速开始

```bash
flutter pub get
flutter test
flutter analyze
```

### Windows 中文路径提示

项目实际位于 `D:\agent_project\情侣共享空间`，但 Flutter 分析服务器在含中文的
路径下会崩溃（`flutter test` 不受影响）。请通过目录联接
`D:\agent_project\couple-space` 进入工程运行 Flutter 命令；
git 与文件操作在两个路径下均可。
