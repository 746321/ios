#!/bin/bash
set -e

# 1. 清理并创建目录
rm -rf build output
mkdir -p build/Payload output

# 2. 强制指定 iOS 原生 arm64 架构编译
xcodebuild archive \
  -project VideoPlayer.xcodeproj \
  -scheme VideoPlayer \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -archivePath build/VideoPlayer.xcarchive \
  -configuration Release \
  PLATFORM_NAME=iphoneos \
  SDKROOT=iphoneos \
  ARCHS="arm64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ASSETCATALOG_COMPILER_APPICON_NAME=""

# 3. 提取 .app 包并动态读取主二进制文件名
APP_PATH=$(find build/VideoPlayer.xcarchive/Products/Applications -name "*.app" | head -n 1)
ditto "$APP_PATH" build/Payload/VideoPlayer.app

PLIST="build/Payload/VideoPlayer.app/Info.plist"
EXEC_NAME=$(plutil -extract CFBundleExecutable raw "$PLIST" 2>/dev/null || echo "VideoPlayer")

# 4. 写入 iOS 平台标识并赋予可执行权限
plutil -replace CFBundleSupportedPlatforms -json '["iPhoneOS"]' "$PLIST" || plutil -insert CFBundleSupportedPlatforms -json '["iPhoneOS"]' "$PLIST"
plutil -replace LSRequiresIPhoneOS -bool true "$PLIST" || plutil -insert LSRequiresIPhoneOS -bool true "$PLIST"

chmod +x "build/Payload/VideoPlayer.app/$EXEC_NAME"
chmod -R 755 build/Payload/VideoPlayer.app

# 5. 打包为标准 IPA
cd build
zip -q -r -y ../output/VideoPlayer.ipa Payload

# 4. 赋予执行权限并压缩为标准 IPA
chmod -R 755 build/Payload/VideoPlayer.app/
cd build
zip -r -y ../output/VideoPlayer.ipa Payload
