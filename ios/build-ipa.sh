#!/bin/bash
# CFData-WEB IPA 一键构建脚本
# 在 macOS 上运行此脚本可自动完成所有构建工作
#
# 用法: ./build-ipa.sh
#
# 前置条件:
#   - macOS 13+ (Ventura 或更新)
#   - Xcode 15+ (含 Command Line Tools)
#   - Go 1.21+
#   - Apple Developer 账号 (用于签名)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
IOS_DIR="$SCRIPT_DIR"
XCODE_PROJECT="${IOS_DIR}/CFData-WEB.xcodeproj"
BUILD_DIR="${IOS_DIR}/build"
ARCHIVE_PATH="${BUILD_DIR}/CFData-WEB.xcarchive"
IPA_OUTPUT="${BUILD_DIR}/CFData-WEB.ipa"
GO_CMD="${GO_CMD:-go}"

echo "============================================"
echo "  CFData-WEB IPA 构建脚本"
echo "============================================"
echo ""

# 检查环境
check_env() {
    echo "[1/5] 检查构建环境..."

    if ! command -v xcodebuild &>/dev/null; then
        echo "错误: 未找到 xcodebuild，请安装 Xcode 和 Command Line Tools"
        exit 1
    fi

    XCODE_VERSION=$(xcodebuild -version | head -1)
    echo "  Xcode: $XCODE_VERSION"

    if ! command -v "$GO_CMD" &>/dev/null; then
        echo "错误: 未找到 Go，请安装 Go 1.21+"
        exit 1
    fi

    echo "  Go: $($GO_CMD version)"

    # 检查 Xcode 开发者账号签名配置
    TEAM_ID=$(xcodebuild -showBuildSettings -project "$XCODE_PROJECT" 2>/dev/null | grep DEVELOPMENT_TEAM | awk '{print $3}' || echo "")
    if [ -z "$TEAM_ID" ]; then
        echo "  警告: 未检测到 Developer Team ID，请在 Xcode 中配置签名"
        echo "  继续构建但可能签名失败..."
    else
        echo "  Team ID: $TEAM_ID"
    fi

    echo "  环境检查通过"
    echo ""
}

# 编译 Go 后端
build_backend() {
    echo "[2/5] 编译 Go 后端 (iOS arm64)..."

    cd "$IOS_DIR"

    CGO_ENABLED=1 \
    GOOS=ios \
    GOARCH=arm64 \
    SDK="iphoneos" \
    SDK_PATH="$(xcrun --sdk $SDK --show-sdk-path)" \
    "$GO_CMD" build \
        -trimpath \
        -ldflags="-s -w" \
        -o "${IOS_DIR}/CFData-WEB/cfdata" \
        "${PROJECT_DIR}/combined_refactor"

    chmod +x "${IOS_DIR}/CFData-WEB/cfdata"

    echo "  后端编译完成"
    echo "  大小: $(du -h "${IOS_DIR}/CFData-WEB/cfdata" | cut -f1)"
    echo ""
}

# 生成应用图标
generate_icon() {
    echo "[3/5] 准备应用图标..."

    ICON_SOURCE="${PROJECT_DIR}/combined_refactor/favicon.png"
    ICON_DIR="${IOS_DIR}/CFData-WEB/Assets.xcassets/AppIcon.appiconset"

    if [ -f "$ICON_SOURCE" ] && [ ! -f "${ICON_DIR}/icon-1024.png" ]; then
        cp "$ICON_SOURCE" "${ICON_DIR}/icon-1024.png"
        echo "  图标已复制"
    else
        echo "  图标已存在或源文件缺失，跳过"
    fi
    echo ""
}

# 创建 Xcode 项目
setup_xcode_project() {
    echo "[4/5] 检查 Xcode 项目配置..."

    if [ -d "$XCODE_PROJECT" ]; then
        echo "  Xcode 项目已存在"
    else
        echo "  请先在 Xcode 中创建项目:"
        echo "    1. 打开 Xcode → File → New → Project"
        echo "    2. 选择 iOS → App"
        echo "    3. Product Name: CFData-WEB"
        echo "    4. Organization Identifier: com.cfdata"
        echo "    5. Interface: SwiftUI, Language: Swift"
        echo "    6. 保存到 ${IOS_DIR}"
        echo ""
        echo "  创建完成后重新运行此脚本"
        exit 1
    fi
    echo ""
}

# 构建并导出 IPA
build_ipa() {
    echo "[5/5] 构建并导出 IPA..."

    # Clean 之前的构建
    xcodebuild clean -project "$XCODE_PROJECT" -scheme "CFData-WEB" -quiet 2>/dev/null || true

    # Archive
    echo "  正在 Archive..."
    xcodebuild archive \
        -project "$XCODE_PROJECT" \
        -scheme "CFData-WEB" \
        -configuration Release \
        -archivePath "$ARCHIVE_PATH" \
        -destination "generic/platform=iOS" \
        -allowProvisioningUpdates \
        | xcpretty || xcodebuild archive \
            -project "$XCODE_PROJECT" \
            -scheme "CFData-WEB" \
            -configuration Release \
            -archivePath "$ARCHIVE_PATH" \
            -destination "generic/platform=iOS" \
            -allowProvisioningUpdates

    if [ ! -d "$ARCHIVE_PATH" ]; then
        echo "错误: Archive 失败"
        exit 1
    fi

    # 导出 IPA
    echo "  正在导出 IPA..."

    EXPORT_OPTIONS_PLIST="${BUILD_DIR}/export-options.plist"
    cat > "$EXPORT_OPTIONS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>ad-hoc</string>
    <key>teamID</key>
    <string>$(xcodebuild -showBuildSettings -project "$XCODE_PROJECT" 2>/dev/null | grep DEVELOPMENT_TEAM | awk '{print $3}' || echo "YOUR_TEAM_ID")</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
    <key>destination</key>
    <string>export</string>
    <key>installerSigningCertificate</key>
    <string>Apple Distribution</string>
</dict>
</plist>
EOF

    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$BUILD_DIR" \
        -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
        -allowProvisioningUpdates

    # 查找导出的 IPA
    EXPORTED_IPA=$(find "$BUILD_DIR" -name "*.ipa" -maxdepth 1 | head -1)
    if [ -f "$EXPORTED_IPA" ]; then
        mv "$EXPORTED_IPA" "$IPA_OUTPUT"
        echo ""
        echo "============================================"
        echo "  IPA 构建成功!"
        echo "  输出: ${IPA_OUTPUT}"
        echo "  大小: $(du -h "$IPA_OUTPUT" | cut -f1)"
        echo "============================================"
    else
        echo "错误: IPA 导出失败，请检查签名配置"
        exit 1
    fi
}

# 主流程
main() {
    check_env
    generate_icon
    build_backend
    setup_xcode_project
    build_ipa

    echo ""
    echo "构建完成! IPA 文件: ${IPA_OUTPUT}"
    echo ""
    echo "部署方式:"
    echo "  1. Ad Hoc: 通过 https://www.diawi.com 上传分发"
    echo "  2. TestFlight: 在 App Store Connect 中上传"
    echo "  3. 企业签名: 使用企业证书重签名后直接分发"
}

main "$@"