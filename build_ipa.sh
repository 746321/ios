#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
SCHEME="VideoPlayer"
ARCHIVE="build/VideoPlayer.xcarchive"
EXPORT="build/export"
rm -rf build
xcodebuild -project VideoPlayer.xcodeproj -scheme "$SCHEME" -configuration Release -sdk iphoneos -archivePath "$ARCHIVE" archive
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportOptionsPlist ExportOptions.plist -exportPath "$EXPORT"
echo "IPA: $EXPORT/VideoPlayer.ipa"
