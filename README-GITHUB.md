# 不需要 Mac 的构建方式

本工程已加入 GitHub Actions 工作流，可以使用 GitHub 提供的 macOS runner 编译 iOS App，并自动生成未签名 IPA。

## 手机也可以操作

1. 在 GitHub 新建一个仓库。
2. 上传本目录中的全部文件（包括 `.github/workflows/build-unsigned-ipa.yml`）。
3. 打开仓库的 **Actions**。
4. 选择 **Build unsigned IPA**。
5. 点击 **Run workflow**。
6. 构建完成后，在该次运行页面底部的 **Artifacts** 下载 `VideoPlayer-unsigned-IPA`。

注意：未签名 IPA 不能直接在普通 iPhone 上安装。需要后续使用自己的 Apple Developer 签名、AltStore/SideStore 等方式重新签名。
