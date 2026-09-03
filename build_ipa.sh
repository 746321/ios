#!/bin/bash
set -e

# 清理并创建目录
rm -rf build output
mkdir -p build/Payload output

# 1. 编译 iOS 包
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

# 2. 复制产物并设置执行权限
cp -R build/VideoPlayer.xcarchive/Products/Applications/*.app build/Payload/
chmod -R 755 build/Payload/*.app

# 3. 打包 IPA
cd build
zip -q -r -y ../output/VideoPlayer.ipa Payload

