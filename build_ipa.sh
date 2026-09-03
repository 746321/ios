#!/bin/bash
set -e

# 清理旧产物
rm -rf build output
mkdir -p build/Payload output

# 1. 编译生成 Archive
xcodebuild archive \
  -project VideoPlayer.xcodeproj \
  -scheme VideoPlayer \
  -archivePath build/VideoPlayer.xcarchive \
  -configuration Release \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ASSETCATALOG_COMPILER_APPICON_NAME=""

# 2. 使用 ditto 完整复制 .app 包（保留文件系统权限与属性）
ditto build/VideoPlayer.xcarchive/Products/Applications/VideoPlayer.app build/Payload/VideoPlayer.app

# 3. 强制赋予主二进制文件可执行权限
chmod -R +x build/Payload/VideoPlayer.app/

# 4. 压缩成 IPA（-y 参数保留符号链接，防止二进制失效）
cd build
zip -r -y ../output/VideoPlayer.ipa Payload
