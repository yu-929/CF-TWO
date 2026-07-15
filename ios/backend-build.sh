#!/bin/bash
# CFData-WEB iOS 后端交叉编译脚本
# 在 macOS 上运行此脚本以编译 iOS arm64 后端

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GO_CMD="${GO_CMD:-go}"
BUILD_DIR="${SCRIPT_DIR}/build"
OUTPUT_BINARY="${SCRIPT_DIR}/CFData-WEB/cfdata"
GO_SOURCE_DIR="$(dirname "$SCRIPT_DIR")/combined_refactor"

echo "=== CFData-WEB iOS 后端交叉编译 ==="
echo "Go: $($GO_CMD version)"
echo "源码目录: ${GO_SOURCE_DIR}"
echo "输出: ${OUTPUT_BINARY}"

if [ ! -f "${GO_SOURCE_DIR}/main.go" ]; then
    echo "错误: 未找到 Go 源码 (${GO_SOURCE_DIR}/main.go)"
    exit 1
fi

build_ios_arm64() {
    echo ""
    echo "--- 编译 iOS arm64 ---"
    mkdir -p "$BUILD_DIR"

    # iOS arm64 需要 CGO_ENABLED=1 + 苹果工具链
    # 在 macOS 上执行时，Xcode 会自动提供必要的 SDK 和编译器
    CGO_ENABLED=1 \
    GOOS=ios \
    GOARCH=arm64 \
    SDK="iphoneos" \
    SDK_PATH="$(xcrun --sdk $SDK --show-sdk-path 2>/dev/null)" \
    "$GO_CMD" build \
        -trimpath \
        -ldflags="-s -w" \
        -o "${BUILD_DIR}/cfdata-ios-arm64" \
        "${GO_SOURCE_DIR}"

    cp "${BUILD_DIR}/cfdata-ios-arm64" "$OUTPUT_BINARY"
    chmod +x "$OUTPUT_BINARY"
    echo "iOS arm64 后端编译完成: $OUTPUT_BINARY"
    echo "大小: $(du -h "$OUTPUT_BINARY" | cut -f1)"
}

build_ios_simulator_arm64() {
    echo ""
    echo "--- 编译 iOS Simulator arm64 ---"
    mkdir -p "$BUILD_DIR"

    CGO_ENABLED=1 \
    GOOS=ios \
    GOARCH=arm64 \
    CGO_CFLAGS="-isysroot $(xcrun --sdk iphonesimulator --show-sdk-path 2>/dev/null)" \
    "$GO_CMD" build \
        -trimpath \
        -tags=iosSimulator \
        -ldflags="-s -w" \
        -o "${BUILD_DIR}/cfdata-ios-sim-arm64" \
        "${GO_SOURCE_DIR}"

    echo "iOS Simulator arm64 编译完成: ${BUILD_DIR}/cfdata-ios-sim-arm64"
}

case "${1:-arm64}" in
    arm64)
        build_ios_arm64
        ;;
    simulator)
        build_ios_simulator_arm64
        ;;
    all)
        build_ios_arm64
        build_ios_simulator_arm64
        ;;
    *)
        echo "用法: $0 [arm64|simulator|all]"
        exit 1
        ;;
esac

echo ""
echo "=== 编译完成 ==="