#!/bin/bash
# CFData-WEB iOS 后端交叉编译脚本
# 用法: ./backend-build.sh [arm64|all]
#
# 前置条件:
#   1. macOS 或 Linux (cross-compile 依赖)
#   2. Go 1.21+
#   3. 如果编译 iOS 原生二进制，需安装 Apple 工具链
#      或者使用 gomobile: go install golang.org/x/mobile/cmd/gomobile@latest
#
# 输出: ios/CFData-WEB/cfdata  (iOS arm64 二进制)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
GO_CMD="${GO_CMD:-/usr/local/go/bin/go}"
BUILD_DIR="${SCRIPT_DIR}/build"
OUTPUT_BINARY="${SCRIPT_DIR}/CFData-WEB/cfdata"

GO_SOURCE_DIR="${PROJECT_DIR}/combined_refactor"

echo "=== CFData-WEB iOS 后端交叉编译 ==="
echo "Go: $($GO_CMD version)"
echo "源码目录: ${GO_SOURCE_DIR}"
echo "输出: ${OUTPUT_BINARY}"

# 检查源码
if [ ! -f "${GO_SOURCE_DIR}/main.go" ]; then
    echo "错误: 未找到 Go 源码 (${GO_SOURCE_DIR}/main.go)"
    exit 1
fi

build_ios_arm64() {
    echo ""
    echo "--- 编译 iOS arm64 ---"

    mkdir -p "$BUILD_DIR"

    CGO_ENABLED=0 \
    GOOS=ios \
    GOARCH=arm64 \
    "$GO_CMD" build \
        -trimpath \
        -ldflags="-s -w" \
        -o "${BUILD_DIR}/cfdata-ios-arm64" \
        "${GO_SOURCE_DIR}"

    cp "${BUILD_DIR}/cfdata-ios-arm64" "$OUTPUT_BINARY"
    chmod +x "$OUTPUT_BINARY"

    file "$OUTPUT_BINARY"
    echo "iOS arm64 后端编译完成: $OUTPUT_BINARY"
    echo "大小: $(du -h "$OUTPUT_BINARY" | cut -f1)"
}

build_macos_arm64() {
    echo ""
    echo "--- 编译 macOS arm64 (测试用) ---"

    mkdir -p "$BUILD_DIR"

    CGO_ENABLED=0 \
    GOOS=darwin \
    GOARCH=arm64 \
    "$GO_CMD" build \
        -trimpath \
        -ldflags="-s -w" \
        -o "${BUILD_DIR}/cfdata-darwin-arm64" \
        "${GO_SOURCE_DIR}"

    echo "macOS arm64 编译完成: ${BUILD_DIR}/cfdata-darwin-arm64"
    echo "大小: $(du -h "${BUILD_DIR}/cfdata-darwin-arm64" | cut -f1)"
}

build_macos_amd64() {
    echo ""
    echo "--- 编译 macOS amd64 (测试用) ---"

    mkdir -p "$BUILD_DIR"

    CGO_ENABLED=0 \
    GOOS=darwin \
    GOARCH=amd64 \
    "$GO_CMD" build \
        -trimpath \
        -ldflags="-s -w" \
        -o "${BUILD_DIR}/cfdata-darwin-amd64" \
        "${GO_SOURCE_DIR}"

    echo "macOS amd64 编译完成: ${BUILD_DIR}/cfdata-darwin-amd64"
    echo "大小: $(du -h "${BUILD_DIR}/cfdata-darwin-amd64" | cut -f1)"
}

case "${1:-arm64}" in
    arm64)
        build_ios_arm64
        ;;
    macos)
        build_macos_arm64
        build_macos_amd64
        ;;
    all)
        build_ios_arm64
        build_macos_arm64
        build_macos_amd64
        ;;
    *)
        echo "用法: $0 [arm64|macos|all]"
        exit 1
        ;;
esac

echo ""
echo "=== 编译完成 ==="