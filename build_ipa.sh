#!/bin/bash
set -e

# 清理旧产物
rm -rf build output
mkdir -p build/Payload output

# 1. 强制关闭 Mac 兼容模式，按原生 iOS 架构编译
xcodebuild archive \
  -project VideoPlayer.xcodeproj \
  -scheme VideoPlayer \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -archivePath build/VideoPlayer.xcarchive \
  -configuration Release \
  SDKROOT=iphoneos \
  SUPPORTED_PLATFORMS=iphoneos \
  SUPPORTS_MACCATALYST=NO \
  IPHONEOS_DEPLOYMENT_TARGET=15.0 \
  TARGETED_DEVICE_FAMILY="1,2" \
  ARCHS="arm64" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ASSETCATALOG_COMPILER_APPICON_NAME=""

# 2. 复制生成的应用程序
ditto build/VideoPlayer.xcarchive/Products/Applications/*.app build/Payload/VideoPlayer.app

# 3. 自动向 Info.plist 注入 iOS 必须的平台头标识（解决签名工具扫描报错）
PLIST="build/Payload/VideoPlayer.app/Info.plist"
plutil -replace CFBundleSupportedPlatforms -json '["iPhoneOS"]' "$PLIST" || plutil -insert CFBundleSupportedPlatforms -json '["iPhoneOS"]' "$PLIST"
plutil -replace MinimumOSVersion -string "15.0" "$PLIST" || plutil -insert MinimumOSVersion -string "15.0" "$PLIST"
plutil -replace LSRequiresIPhoneOS -bool true "$PLIST" || plutil -insert LSRequiresIPhoneOS -bool true "$PLIST"

# 4. 赋予执行权限并压缩为标准 IPA
chmod -R 755 build/Payload/VideoPlayer.app/
cd build
zip -r -y ../output/VideoPlayer.ipa Payload
