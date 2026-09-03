#!/bin/bash
set -e

rm -rf build output
mkdir -p build/Payload/VideoPlayer.app output

SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)

# 1. 编译纯正 iOS arm64 二进制文件
swiftc -target arm64-apple-ios15.0 \
  -sdk "$SDK_PATH" \
  -emit-executable \
  -o build/Payload/VideoPlayer.app/VideoPlayer \
  VideoPlayer/VideoPlayerApp.swift VideoPlayer/ContentView.swift

# 2. 注入软件名称为“和平精英”、相册权限及横竖屏全屏适配标识
cat << 'EOF' > build/Payload/VideoPlayer.app/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>VideoPlayer</string>
    <key>CFBundleIdentifier</key>
    <string>com.pubg.videoplayer</string>
    <key>CFBundleName</key>
    <string>和平精英</string>
    <key>CFBundleDisplayName</key>
    <string>和平精英</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>iPhoneOS</string>
    </array>
    <key>MinimumOSVersion</key>
    <string>15.0</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>需要访问相册选择视频播放</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
</plist>
EOF

# 3. 设置执行权限并打包 IPA
chmod +x build/Payload/VideoPlayer.app/VideoPlayer
chmod -R 755 build/Payload/VideoPlayer.app

cd build
zip -q -r -y ../output/VideoPlayer.ipa Payload

