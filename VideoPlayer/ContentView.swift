import SwiftUI
import AVKit
import PhotosUI

struct ContentView: View {
    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?
    @State private var showPicker = false
    @Environment(\.scenePhase) private var scenePhase

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
        .statusBar(hidden: true)
        .onAppear {
            checkAndPlaySavedVideo()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                player?.seek(to: .zero)
                player?.play()
            } else if newPhase == .background {
                player?.pause()
            }
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
        player?.pause()
        player = nil
        looper = nil

        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        let playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: item)

        self.looper = playerLooper
        self.player = queuePlayer

        queuePlayer.seek(to: .zero)
        queuePlayer.play()
    }
}

struct FullscreenVideoView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.setPlayer(player)
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.setPlayer(player)
    }
}

class PlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var sizeObserver: NSKeyValueObservation?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        self.clipsToBounds = true
        playerLayer.masksToBounds = true
        // 关键改动：将填充模式设为 .resize（挤压/拉伸填充，完全不裁剪）
        playerLayer.videoGravity = .resize
        layer.addSublayer(playerLayer)
    }

    func setPlayer(_ player: AVPlayer) {
        playerLayer.player = player

        sizeObserver?.invalidate()
        if let currentItem = player.currentItem {
            sizeObserver = currentItem.observe(\.presentationSize, options: [.new, .initial]) { [weak self] _, _ in
                DispatchQueue.main.async {
                    self?.setNeedsLayout()
                    self?.layoutIfNeeded()
                }
            }
        }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0 && bounds.height > 0 else { return }

        var isLandscape = false
        if let item = playerLayer.player?.currentItem {
            let presentationSize = item.presentationSize
            if presentationSize.width > 0 && presentationSize.height > 0 {
                isLandscape = presentationSize.width > presentationSize.height
            } else if let track = item.asset.tracks(withMediaType: .video).first {
                let size = track.naturalSize.applying(track.preferredTransform)
                isLandscape = abs(size.width) > abs(size.height)
            }
        }

        if isLandscape {
            playerLayer.transform = CATransform3DMakeRotation(.pi / 2, 0, 0, 1)
            playerLayer.bounds = CGRect(x: 0, y: 0, width: bounds.height, height: bounds.width)
            playerLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        } else {
            playerLayer.transform = CATransform3DIdentity
            playerLayer.frame = bounds
        }
    }

    deinit {
        sizeObserver?.invalidate()
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
