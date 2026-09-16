# AI Server iPhone Client

这是一个 SwiftUI iPhone 客户端源码，基于 `API.md` 的约定实现：

- Keychain 保存 API Token；
- 所有受保护请求使用 Bearer Token；
- 服务器状态、进程、服务、Docker、聊天、任务与审计；
- WebSocket 实时事件与高风险任务的确认/拒绝；
- 不在客户端构造或执行 shell 命令。

## 在 Windows 上构建并安装（免费，每 7 天续签）

项目已附带 GitHub Actions 工作流 [build-ios-ipa.yml](.github/workflows/build-ios-ipa.yml)，会在 GitHub 的 macOS 环境编译出**未签名 IPA**。它不需要、也绝不应当保存你的 Apple ID、密码或证书。

1. 注册 GitHub 账号，新建 GitHub 仓库，将本目录上传或推送到该仓库。若仓库设为**公开**，GitHub 的标准 macOS Actions runner 免费；若设为私有，则使用 GitHub Free 每月附带的 Actions 额度。无论仓库类型，绝不要提交 API Token、Apple ID 或密码。
2. GitHub 仓库打开 `Actions` → `Build iOS IPA` → `Run workflow`。
3. 等待构建完成，在该工作流页面最下方的 `Artifacts` 下载 `AIServerClient-unsigned-ipa`，解压得到 `AIServerClient-unsigned.ipa`。
4. Windows 安装 Sideloadly 和 Apple 官方版 iTunes/iCloud，USB 连接 iPhone 并选择“信任”。
5. 在 Sideloadly 选择这个 IPA 和你的 Apple ID，点击 Start。密码只输入在 Sideloadly；若 Apple ID 开启双重认证，请在 Apple ID 网站创建“App 专用密码”。
6. 手机进入“设置 → 通用 → VPN 与设备管理”，信任对应的开发者；首次启动 App 后在设置中录入 API Token。
7. 第 7 天前再次用 Sideloadly 对同一个 IPA 执行一次安装，即完成续签。

免费个人团队的设备安装证书有效期为 7 天，且 Apple 对可注册的 App ID、设备和每设备 App 数量有配额；这是 Apple 的限制，不是本项目的限制。

## 在 Xcode 中运行

1. 安装 [XcodeGen](https://github.com/yonaskolb/XcodeGen)，或以 `project.yml` 新建同名 iOS App 工程。
2. 在此目录运行 `xcodegen generate`，打开生成的 `AIServerClient.xcodeproj`。
3. 将 Signing Team 设为自己的 Apple 开发团队，选择 iOS 17+ 模拟器或真机运行。
4. 首次启动时，在“设置”中输入 API Token 并保存。

默认 API 地址为 `https://msadream.cn/agent`。若部署地址不同，可在设置中修改。
