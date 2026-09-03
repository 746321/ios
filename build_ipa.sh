#!/bin/bash
set -e

# 清理旧产物
rm -rf build output
mkdir -p build/Payload output

# 1. 强制使用 iOS SDK 与 arm64 架构编译 Archive
xcodebuild archive \
  -project VideoPlayer.xcodeproj \
  -scheme VideoPlayer \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -archivePath build/VideoPlayer.xcarchive \
  -configuration Release \
  SDKROOT=iphoneos \
  SUPPORTED_PLATFORMS=iphoneos \
  TARGETED_DEVICE_FAMILY="1,2" \
  ARCHS="arm64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ASSETCATALOG_COMPILER_APPICON_NAME=""

# 2. 复制编译出的应用程序
ditto build/VideoPlayer.xcarchive/Products/Applications/*.app build/Payload/VideoPlayer.app

# 3. 赋予可执行文件 755 权限
chmod -R 755 build/Payload/VideoPlayer.app/

# 4. 打包生成 IPA
cd build
zip -r -y ../output/VideoPlayer.ipa Payload

