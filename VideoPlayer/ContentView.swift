import SwiftUI
import AVKit
import PhotosUI

struct ContentView: View {
    @State private var player: AVPlayer?
    @State private var showPicker = false

    private var savedVideoURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("saved_video.mp4")
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = player {
                FullscreenVideoView(player: player)
                    .ignoresSafeArea(.all)
                    .onLongPressGesture {
                        showPicker = true
                    }
            } else {
                VStack(spacing: 20) {
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
        }
        .statusBar(hidden: true) // 强制隐藏 iOS 顶部状态栏
        .onAppear {
            checkAndPlaySavedVideo()
        }
        .sheet(isPresented: $showPicker) {
            VideoPicker { selectedURL in
                saveAndPlayVideo(from: selectedURL)
            }
        }
    }

    private func checkAndPlaySavedVideo() {
        if FileManager.default.fileExists(atPath: savedVideoURL.path) {
            startLoopingPlayer(url: savedVideoURL)
        } else {
            showPicker = true
        }
    }

    private func saveAndPlayVideo(from sourceURL: URL) {
        try? FileManager.default.removeItem(at: savedVideoURL)
        try? FileManager.default.copyItem(at: sourceURL, to: savedVideoURL)
        startLoopingPlayer(url: savedVideoURL)
    }

    private func startLoopingPlayer(url: URL) {
        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)

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

struct FullscreenVideoView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
}

class PlayerUIView: UIView {
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

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

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VideoPicker
        init(_ parent: VideoPicker) { self.parent = parent }

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
