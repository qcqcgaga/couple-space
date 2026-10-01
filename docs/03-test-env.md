# 情侣共享空间 · 本地测试环境

- 版本：v1.0（基线）
- 定稿日期：2026-10-01
- 状态：已定稿；M1 阶段先验证本文档中“待验证”项

## 1. 结论速览

| 测试对象 | 可用环境 | 备注 |
| --- | --- | --- |
| 同步引擎/协议逻辑 | Windows 本机 `dart test` | 内存假传输 + 双进程 TCP 实测，不依赖设备 |
| Android UI / 局域网 | Mumu 多开 或 Android Studio AVD | Mumu 多开互通性需先探测 |
| Android 蓝牙 / 热点 | 真机 | 模拟器无真实蓝牙，热点难真实模拟 |
| iOS 构建 | 云端 macOS CI（免费档） | Windows 无法本地构建 iOS，只能走云端 |
| iOS 模拟器冒烟 | 云端 CI（macOS runner 内置 Xcode/模拟器） | 不能本机运行，CI 可跑无头模拟器测试 |
| iOS 真机安装 | 免费 Apple ID + Sideloadly/AltStore | 无需 Mac；7 天重签一次 |
| Android↔iOS 局域网 | Mac 上 iOS 模拟器 + Android 模拟器，或两台真机 | 跨端联调首选真机 |
| Android↔iOS 蓝牙 / 热点 | 两台真机 | 必须真机 |

## 2. Mumu 模拟器评估

**结论：Mumu 适合 Android 侧快速开发与 UI 冒烟，但不适合作为唯一测试环境。**

### 可以用

- 多开两个实例，模拟“两台 Android 设备”。
- Android UI 快速迭代、权限流程、通知、存储逻辑验证。
- 局域网路径的初步验证（需先做连通性探测，见 §4）。

### 不可以用

- 蓝牙：无真实蓝牙栈，无法模拟 BLE 连接。
- 热点：难以真实模拟“一台设备开热点、另一台加入”的链路。
- iOS：Mumu 只跑 Android，与 iPhone 测试无关。

### 风险

- Mumu 多开实例之间的网络互通可能受虚拟网卡/NAT 限制；
  必须先用探针确认“互相可见 + TCP 可连”。
- 若不通：切换 Android Studio AVD（同一宿主机的多个 AVD 网络互通更可控）。

## 3. 本机环境规划（Windows）

- Flutter SDK + Dart SDK、Android SDK、adb。
- 开发日常：
  - 逻辑层：`flutter test` / `dart test`（假传输、双进程、真 TCP 循环回环）。
  - Android：Mumu 双开或 AVD；真机用于蓝牙/热点。
  - iOS：见 §5。

## 4. M1 阶段必须做的两个探针

### 探针 A：本机协议自测

- 两个 Dart 进程：一个做 mDNS 服务端，一个做客户端；
  验证“发现 + TCP echo + 分帧协议”在本机回环网络工作。
- 该探针同时就是同步引擎集成测试的基座。

### 探针 B：Mumu 双开互通

- 在 Mumu 两个实例安装同一个探针 App（Flutter 小程序）：
  互相 mDNS 发现 + TCP 互连，各显示对方设备ID。
- 通过：局域网自动连接路径可在 Mumu 上继续开发。
- 不通过：改用两个 AVD，或一个 AVD + 一台真机同 WiFi。

## 5. iPhone 怎么测试（重点）

### 硬性事实

- iOS 的构建、真机签名、模拟器运行**都依赖 macOS + Xcode**。
- 在 Windows 上无法运行 iOS 模拟器，也无法产出 iOS 安装包。
- 但是：**没有 Mac 不等于没有免费构建路线**，云端 macOS 可替代构建环节。

### 无 Mac 的免费构建路线（按推荐排序）

| 路线 | 免费额度 | 适用情况 |
| --- | --- | --- |
| GitHub Actions **macOS runner**（公开仓库） | 公开仓库的标准 runner 免费 | **本项目已选：仓库开源，走此路线** |
| **Codemagic** 免费档 | 约 500 分钟/月（macOS，Flutter 友好） | 私有仓库首选，适合日常持续构建 |
| GitHub Actions（私有仓库） | 2000 分钟/月，但 macOS 按 10 倍计费 → 实际约 200 分钟 | 只适合偶尔出包，不适合高频迭代 |
| Bitrise 等 | 免费档额度很小 | 备选 |

> 注意：所有“免费”均受平台政策约束，不保证长期不变；严格说没有
> “免费的本地 Mac”。若未来 iOS 开发变高频，二手 Mac mini 或按小时租云端
> Mac 是更稳的方案。

### iOS 真机安装（不需要 Mac）

- CI 产出 .ipa（可不签名构建）后，用 **Sideloadly / AltStore**（Windows 上操作）
  配合**免费 Apple ID** 签名安装到 iPhone。
- 限制：免费 Apple ID 签名 7 天过期需重签，可注册设备数量有限（约 3 台以内）。
- **长期稳定签名的选项（都不强制上架 App Store）**：
  - $99/年 Apple Developer 账号 + **Ad Hoc 分发**：直接安装到已注册设备
    （最多 100 台），签名/描述文件一年一续，**不需要上架、不需要审核**。
  - $99/年账号 + **TestFlight**：内测免审核，但构建 90 天过期需重新上传。
  - $99/年账号 + **App Store**：上架需要审核，才属于“必须过商店”的路径。
  - 企业版（$299/年，需公司资质）不适用于个人/情侣场景。

### 推荐的组合策略（无 Mac 版）

1. **日常开发**：Windows + Mumu/AVD 跑 Android 与共享 Dart 逻辑；
   iOS 专属代码（BLE 平台通道等）在 Windows 编写，语法/逻辑靠 Dart 单测兜底。
2. **iOS 构建与模拟器冒烟**：走 **GitHub Actions macOS runner**（仓库已决定开源）；
   CI 的 macOS runner 内置 Xcode，可跑无头模拟器测试。Codemagic 作为私有化需求
   出现时的备选。
3. **蓝牙/热点真机联调**：需要一台 iPhone + 一台 Android 真机，在真实
   WiFi/热点/蓝牙环境中跑通三条通道——iPhone 用免费 Apple ID 安装即可。

> 对项目的影响：iOS 端代码很薄（BLE、权限、通知），大部分工作在 Windows
> 完成；iOS 构建低频、按需走 CI，完全可行。跨端局域网联调最终仍需要
> 两台真机（可以在 Mac 上双模拟器联调，但这不是必要条件）。

### 推荐的组合策略

1. **日常开发**：Windows + Mumu/AVD 跑 Android 与共享 Dart 逻辑；
   iOS 专属代码（BLE 平台通道等）先在 Windows 写，语法/逻辑靠 Dart 单测兜底。
2. **iOS 构建与模拟器冒烟**：使用 macOS 环境，二选一：
   - 有 Mac：本机 Xcode + iOS Simulator，两个模拟器可测 iOS 双端局域网；
     还能同时开 Android 模拟器，做 Android↔iOS 局域网联调。
   - 没有 Mac：GitHub Actions 的 **macOS runner**（免费额度内）做 iOS
     构建、单测、模拟器冒烟；但**真机安装仍需要签名配置**（开发者账号）。
3. **蓝牙/热点真机联调**：至少需要一台 iPhone + 一台 Android 真机，
   在真实 WiFi/热点/蓝牙环境中跑通三条通道。

> 建议：先以“Mac 或 macOS CI + 两台真机”为最终验收环境，
> Windows 阶段只承诺完成 M1 共享核心与 Android 侧开发验证。

## 6. 推荐的开发-测试矩阵

| 阶段 | 逻辑 | Android | iOS | 跨端 |
| --- | --- | --- | --- | --- |
| M1 | Windows `dart test` | — | — | 双进程协议测试 |
| M2 | Windows | Mumu/AVD UI 冒烟 | — | — |
| M3 | Windows | Android 真机（蓝牙/热点） | — | — |
| M4 | — | — | 云端 CI 构建 + 模拟器冒烟 | 两台真机（Android + iPhone） |
| M5 | Windows | Android 真机 | iPhone 真机 | 两台真机全路径 |

## 7. 需要的测试资产清单

- Windows 开发机（现有）。
- Mumu 多开（现有，需验证互通）。
- Android 真机一台（用于蓝牙/热点，也兼开发机）。
- iPhone 一台（最终联调）。
- GitHub Actions macOS runner（仓库开源）用于 iOS 构建；Codemagic 为备选。
- iPhone 一台（免费 Apple ID + Sideloadly/AltStore 安装，不需要 Mac）。
