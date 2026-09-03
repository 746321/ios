# 视频播放器 iOS 版

这是根据提供的 Android APK 的核心功能重新实现的 iOS 工程：选择本地视频、全屏播放、自动循环，并记住上次选择的视频。

## 环境
- macOS
- Xcode 15 或更新版本
- iOS 16+
- 真机安装/IPA 导出需要 Apple Developer 签名能力

## 打开工程
双击 `VideoPlayer.xcodeproj`，在 Signing & Capabilities 中选择你自己的 Apple Developer Team，并按需修改 Bundle Identifier。

## 导出 IPA
终端进入工程目录执行：

```bash
./build_ipa.sh
```

脚本会执行 Archive + Export。若账号/证书配置正确，IPA 位于 `build/export/VideoPlayer.ipa`。

## 功能
- 文件 App 中选择视频
- AVPlayer 全屏播放
- 播放结束自动从头循环
- 横竖屏适配
- 记住上次选择的视频
- 保留原 APK 中“视频播放器 / 请选择要自动循环播放的视频 / 选择视频”的核心文案

说明：当前运行环境不是 macOS/Xcode，因此这里生成的是完整 Xcode 工程和 IPA 构建配置，无法在本环境执行 Apple 的代码签名与最终 IPA 导出。
