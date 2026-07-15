# CFData-WEB iOS IPA 构建指南

## 项目结构

```
ios/
├── backend-build.sh              # Go 后端交叉编译脚本
├── README.md                     # 本文件
├── CFData-WEB.xcodeproj/         # Xcode 项目（需在 Xcode 中创建）
└── CFData-WEB/                   # iOS 应用源码
    ├── CFData_WEBApp.swift       # SwiftUI 入口
    ├── ContentView.swift         # 主视图（WKWebView + 加载/错误状态）
    ├── WebView.swift             # WKWebView UIViewRepresentable 封装
    ├── BackendManager.swift      # 后端生命周期管理（本地/远程模式）
    ├── SettingsView.swift        # 设置视图
    ├── CFData-WEB.entitlements   # 授权文件
    ├── Info.plist                # 应用配置
    └── Assets.xcassets/          # 资源文件
        ├── Contents.json
        ├── AppIcon.appiconset/   # 应用图标
        └── AccentColor.colorset/ # 主题色
```

## 架构说明

iOS 版本支持两种工作模式：

### 1. 本地模式（推荐）
嵌入式 Go 后端在 iOS 上以独立进程运行，WKWebView 连接 `http://127.0.0.1:13335`，与 Android APK 工作方式一致。

### 2. 远程模式
连接外部 CFData 服务器（自建或个人部署），适用于不想嵌入后端的场景。

## 构建步骤

### 前置条件

- macOS 13+（Ventura 或更新版本）
- Xcode 15+
- Go 1.21+

### 步骤 1：编译 Go 后端

```bash
# 给编译脚本添加执行权限
chmod +x ios/backend-build.sh

# 编译 iOS arm64 后端
./ios/backend-build.sh arm64
```

输出文件：`ios/CFData-WEB/cfdata`（iOS arm64 可执行文件）

### 步骤 2：在 Xcode 中创建项目

1. 打开 Xcode
2. 选择 File → New → Project
3. 选择 iOS → App
4. 配置项目：
   - Product Name: `CFData-WEB`
   - Team: 选择你的 Apple Developer 账号
   - Organization Identifier: `com.cfdata`
   - Interface: SwiftUI
   - Language: Swift
5. 将项目保存到 `ios/CFData-WEB.xcodeproj`

### 步骤 3：导入源码文件

创建 Xcode 项目后，用以下文件替换 Xcode 生成的默认文件：

| Xcode 默认文件 | 替换为 |
|---------------|--------|
| `CFData_WEBApp.swift` | `ios/CFData-WEB/CFData_WEBApp.swift` |
| `ContentView.swift` | `ios/CFData-WEB/ContentView.swift` |
| (新建) | `ios/CFData-WEB/WebView.swift` |
| (新建) | `ios/CFData-WEB/BackendManager.swift` |
| (新建) | `ios/CFData-WEB/SettingsView.swift` |

在 Xcode 中：
1. 右键项目导航栏 → Add Files to "CFData-WEB" → 选择上述文件
2. 确保 `Info.plist` 中的字段与项目配置一致（Bundle Identifier 等）
3. 添加 `CFData-WEB.entitlements` 到项目中

### 步骤 4：嵌入 Go 后端

1. 在 Xcode 项目导航栏中，右键项目 → Add Files to "CFData-WEB"
2. 选择 `ios/CFData-WEB/cfdata` 文件
3. 在弹出的对话框中：
   - 勾选 "Copy items if needed"
   - Add to targets: 勾选 `CFData-WEB`
4. 在 Build Phases 中，确认 `cfdata` 出现在 "Copy Bundle Resources" 中

### 步骤 5：配置 Info.plist

确保 `Info.plist` 包含以下键值：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSAllowsArbitraryLoadsInWebContent</key>
    <true/>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

这是必需的，因为后端通过 HTTP（非 HTTPS）提供服务。

### 步骤 6：配置 Signing & Capabilities

1. 在 Xcode 项目设置中，选择 `CFData-WEB` target
2. Signing & Capabilities 标签页
3. 选择你的 Apple Developer Team
4. 确保 Bundle Identifier 为 `com.cfdata.web`（或自定义，需与 Info.plist 一致）

### 步骤 7：构建并导出 IPA

#### 真机调试
1. 连接 iOS 设备
2. 选择设备为目标
3. 按 Cmd+R 运行

#### 导出 IPA（Ad Hoc / App Store）
1. 选择 Product → Archive
2. 在 Organizer 中，点击 "Distribute App"
3. 选择分发方式（Ad Hoc / TestFlight / App Store）
4. 按向导完成导出

## 常见问题

### Q: iOS 不允许运行独立二进制？
A: 通过 `Process()` API 启动 bundled executable 在 iOS 上是允许的，但注意：
- 需要绕过 `amfid` 代码签名验证——内置二进制必须与主应用使用同一证书签名
- Xcode 在构建时自动处理签名
- 建议使用 `gomobile bind` 将 Go 编译为 framework 作为替代方案

### Q: App Store 审核会拒绝吗？
A: 可能的风险：
- iOS 应用启动独立 TCP 监听进程可能触发审核审查
- 如果被拒，建议切换到**远程模式**提交审核
- 或者使用企业证书进行内部分发

### Q: 如何在不上架 App Store 的情况下安装？
A: 使用以下方法：
1. **Ad Hoc 分发**：注册设备 UDID，导出 Ad Hoc IPA
2. **TestFlight**：通过 TestFlight 内测分发
3. **企业证书**：有 Apple Enterprise 账号可内部签名分发

### Q: 能否使用 gomobile 替代？
A: 可以。替代方案是使用 `gomobile bind` 将 Go 后端编译为 iOS Framework：

```bash
go install golang.org/x/mobile/cmd/gomobile@latest
gomobile init
gomobile bind -target=ios -iosversion=15.0 \
    -o ios/CFData-WEB/Backend.framework \
    ./ios/bridge/
```

然后需要创建一个 `bridge` 包，将 HTTP 服务器启动逻辑封装为可导出函数。

## 完整的构建命令

```bash
# 1. 编译 Go 后端
cd /path/to/CFData-WEB
chmod +x ios/backend-build.sh
./ios/backend-build.sh arm64

# 2. 打开 Xcode 项目，按步骤配置
open ios/CFData-WEB.xcodeproj

# 3. 在 Xcode 中执行 Archive → Export IPA
```