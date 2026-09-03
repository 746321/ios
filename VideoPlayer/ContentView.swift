import SwiftUI
import AVKit
import PhotosUI

struct ContentView: View {
    @State private var player: AVPlayer?
    @State private var showPicker = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = player {
                VideoPlayerView(player: player)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.green)

                    Text("和平精英")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)

                    Button(action: { showPicker = true }) {
                        Text("选择视频并播放")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(Color.green)
                            .cornerRadius(25)
                    }
                }
            }

            // 播放界面左上角悬浮更换视频按钮
            if player != nil {
                VStack {
                    HStack {
                        Button(action: { showPicker = true }) {
                            Image(systemName: "film")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding()
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            VideoPicker { url in
                setupPlayer(with: url)
            }
        }
    }

    private func setupPlayer(with url: URL) {
        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        
        // 监听播放结束，实现自动循环播放
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            newPlayer.seek(to: .zero)
            newPlayer.play()
        }
        
        self.player = newPlayer
        newPlayer.play()
    }
}

// 视频播放控制器（原生支持全屏、横竖屏自适应）
struct VideoPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspect
        controller.allowsPictureInPicturePlayback = true
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        controller.player = player
    }
}

// iOS 相册视频选择器
struct VideoPicker: UIViewControllerRepresentable {
    var onSelect: (URL) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VideoPicker

        init(_ parent: VideoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.hasItemConformingToTypeIdentifier("public.movie") else { return }

            provider.loadFileRepresentation(forTypeIdentifier: "public.movie") { url, error in
                guard let url = url else { return }
                let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.removeItem(at: tempUrl)
                try? FileManager.default.copyItem(at: url, to: tempUrl)
                
                DispatchQueue.main.async {
                    self.parent.onSelect(tempUrl)
                }
            }
        }
    }
}
