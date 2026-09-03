import SwiftUI
import AVKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var model = VideoPlayerModel()
    @State private var showImporter = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = model.player {
                PlayerContainer(player: player)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 18) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 64))
                    Text("视频播放器")
                        .font(.title2.bold())
                    Text("请选择要自动循环播放的视频")
                        .foregroundStyle(.secondary)
                    Button {
                        showImporter = true
                    } label: {
                        Label("选择视频", systemImage: "folder")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 13)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .foregroundStyle(.white)
                .padding()
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        showImporter = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                            .font(.title3.bold())
                            .padding(12)
                            .background(.black.opacity(0.55), in: Circle())
                    }
                    .foregroundStyle(.white)
                    .padding()
                }
                Spacer()
            }
            .opacity(model.player == nil ? 0 : 1)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showImporter) {
            VideoImporter { url in
                model.load(url: url)
                showImporter = false
            }
            .ignoresSafeArea()
        }
    }
}

@MainActor
final class VideoPlayerModel: ObservableObject {
    @Published var player: AVPlayer?
    private let bookmarkKey = "savedVideoBookmark"

    init() {
        restoreSavedVideo()
    }

    func load(url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        do {
            let bookmark = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmark, forKey: bookmarkKey)
        } catch {
            // Some local URLs don't support security-scoped bookmarks; playback still works.
        }

        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.actionAtItemEnd = .none
        player = newPlayer

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak newPlayer] _ in
            newPlayer?.seek(to: .zero)
            newPlayer?.play()
        }

        newPlayer.play()
    }

    private func restoreSavedVideo() {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return }
        var stale = false
        do {
            let url = try URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &stale)
            if stale {
                let refreshed = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
                UserDefaults.standard.set(refreshed, forKey: bookmarkKey)
            }
            if url.startAccessingSecurityScopedResource() {
                let item = AVPlayerItem(url: url)
                let restoredPlayer = AVPlayer(playerItem: item)
                restoredPlayer.actionAtItemEnd = .none
                player = restoredPlayer
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak restoredPlayer] _ in
                    restoredPlayer?.seek(to: .zero)
                    restoredPlayer?.play()
                }
                restoredPlayer.play()
            }
        } catch {
            UserDefaults.standard.removeObject(forKey: bookmarkKey)
        }
    }
}

struct PlayerContainer: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspect
        controller.entersFullScreenWhenPlaybackBegins = true
        controller.exitsFullScreenWhenPlaybackEnds = false
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        controller.player = player
    }
}

struct VideoImporter: UIViewControllerRepresentable {
    let completion: (URL) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.movie, .mpeg4Movie, .quickTimeMovie, .video]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: false)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let completion: (URL) -> Void
        init(completion: @escaping (URL) -> Void) { self.completion = completion }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            completion(url)
        }
    }
}
