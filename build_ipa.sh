#!/bin/bash
set -e

# 清理旧产物
rm -rf build output
mkdir -p build/Payload output

# 1. 编译生成 Archive（强制指定 iOS SDK 与架构）
xcodebuild archive \
  -project VideoPlayer.xcodeproj \
  -scheme VideoPlayer \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -archivePath build/VideoPlayer.xcarchive \
  -configuration Release \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ASSETCATALOG_COMPILER_APPICON_NAME=""

# 2. 复制编译出的 iOS 应用程序到 Payload 目录
ditto build/VideoPlayer.xcarchive/Products/Applications/*.app build/Payload/VideoPlayer.app

# 3. 赋予可执行权限
chmod -R 755 build/Payload/VideoPlayer.app/

# 4. 重新压缩为标准 IPA
cd build
zip -r -y ../output/VideoPlayer.ipa Payload
