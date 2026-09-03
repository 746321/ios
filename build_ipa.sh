#!/bin/bash
set -e

# 清理旧产物
rm -rf build output
mkdir -p output

# 编译生成 Archive（禁用签名与图标校验）
xcodebuild archive \
  -project VideoPlayer.xcodeproj \
  -scheme VideoPlayer \
  -archivePath build/VideoPlayer.xcarchive \
  -configuration Release \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ASSETCATALOG_COMPILER_APPICON_NAME=""

# 打包成 IPA
mkdir -p build/Payload
cp -r build/VideoPlayer.xcarchive/Products/Applications/*.app build/Payload/
cd build
zip -r ../output/VideoPlayer.ipa Payload
