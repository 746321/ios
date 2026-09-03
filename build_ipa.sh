#!/bin/bash
set -e

# 清理旧编译产物
rm -rf build output
mkdir -p output

# 编译生成 Archive（强制禁用签名）
xcodebuild archive \
  -project VideoPlayer.xcodeproj \
  -scheme VideoPlayer \
  -archivePath build/VideoPlayer.xcarchive \
  -configuration Release \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# 手动打成未签名 IPA 包
mkdir -p build/Payload
cp -r build/VideoPlayer.xcarchive/Products/Applications/*.app build/Payload/
cd build
zip -r ../output/VideoPlayer.ipa Payload
