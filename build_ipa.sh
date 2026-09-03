#!/bin/bash
set -e

# 1. 清理旧构建产物
rm -rf build output
mkdir -p build/Payload output

# 2. 自动把 Xcode 工程文件中的 macOS 架构强制替换为 iOS 原生架构
python3 -c '
pbx = "VideoPlayer.xcodeproj/project.pbxproj"
try:
    with open(pbx, "r") as f:
        c = f.read()
    c = c.replace("SDKROOT = macosx;", "SDKROOT = iphoneos;")
    c = c.replace("SUPPORTED_PLATFORMS = \"macosx maccatalyst\";", "SUPPORTED_PLATFORMS = \"iphoneos\";")
    c = c.replace("SUPPORTS_MACCATALYST = YES;", "SUPPORTS_MACCATALYST = NO;")
    with open(pbx, "w") as f:
        f.write(c)
    print("Project patched to iOS native successfully.")
except Exception as e:
    print("Patch info:", e)
'

# 3. 编译原生 iOS arm64 架构 Archive
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
  ARCHS="arm64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ASSETCATALOG_COMPILER_APPICON_NAME=""

# 4. 提取应用文件并写入 iOS 必备信息头（解决全能签扫描报错）
ditto build/VideoPlayer.xcarchive/Products/Applications/*.app build/Payload/VideoPlayer.app

PLIST="build/Payload/VideoPlayer.app/Info.plist"
plutil -replace CFBundleSupportedPlatforms -json '["iPhoneOS"]' "$PLIST" 2>/dev/null || plutil -insert CFBundleSupportedPlatforms -json '["iPhoneOS"]' "$PLIST"
plutil -replace LSRequiresIPhoneOS -bool true "$PLIST" 2>/dev/null || plutil -insert LSRequiresIPhoneOS -bool true "$PLIST"

# 5. 赋予二进制文件执行权限并打包 IPA
chmod -R 755 build/Payload/VideoPlayer.app
cd build
zip -q -r -y ../output/VideoPlayer.ipa Payload


