import SwiftUI
import AVKit
import WebKit

struct PlayerView: View {
    let movie: Movie
    let server: SourceServer
    @State var episode: Episode
    let allEpisodes: [Episode]
    @Environment(AppState.self) private var state

    @State private var controller = PlayerController()
    @State private var showControls = true
    @State private var useEmbedPlayer = false
    @State private var isHoldingToSpeedUp = false
    @State private var originalRate: Float = 1.0
    @State private var isZoomToFill = false
    @State private var zoomFeedback: String? = nil
    @State private var zoomFeedbackTask: Task<Void, Never>?
    @State private var seekFeedback: Bool? = nil
    @State private var seekFeedbackTask: Task<Void, Never>?
    @State private var dismissTask: Task<Void, Never>?
    @State private var autoHideTask: Task<Void, Never>?
    @State private var pipLayer: AVPlayerLayer?
    @State private var autoSaveTask: Task<Void, Never>?
    @Environment(\.dismiss) private var dismiss

    private var currentIndex: Int { allEpisodes.firstIndex(where: { $0.id == episode.id }) ?? 0 }
    private var nextEpisode: Episode? {
        let idx = currentIndex + 1
        return idx < allEpisodes.count ? allEpisodes[idx] : nil
    }

    private var isEmbedMode: Bool {
        if useEmbedPlayer { return true }
        if server == .nguonc || server == .vsmov { return true }
        if let m3u8 = episode.linkM3U8, !m3u8.isEmpty, m3u8.contains(".m3u8") {
            return false
        }
        return episode.linkEmbed != nil && !(episode.linkEmbed?.isEmpty ?? true)
    }

    private var embedURL: URL? {
        let raw = episode.linkEmbed ?? episode.linkM3U8
        guard let raw, let url = URL(string: raw) else { return nil }
        return url
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                if isEmbedMode, let url = embedURL {
                    EmbedPlayerRepresentable(url: url)
                        .ignoresSafeArea()

                    // Floating Exit and Episode controls for Server 3 Embed
                    VStack {
                        HStack(spacing: DFSpacing.md) {
                            Button {
                                OrientationManager.setOrientation(.portrait)
                                dismiss()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .bold))
                                    Text("Thoát")
                                        .font(DFFont.caption().bold())
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.75))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.8))
                                .shadow(color: .black.opacity(0.6), radius: 6, y: 2)
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(movie.name)
                                    .font(DFFont.caption().bold())
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text("\(episode.name) · \(server.displayName)")
                                    .font(DFFont.small())
                                    .foregroundStyle(DFColor.gold)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            Spacer()

                            episodePicker
                        }
                        .padding(.leading, max(geo.safeAreaInsets.leading, 24))
                        .padding(.trailing, max(geo.safeAreaInsets.trailing, 24))
                        .padding(.top, max(geo.safeAreaInsets.top, 12))

                        Spacer()
                    }
                    .zIndex(150)
                } else {
                    VideoPlayerRepresentable(player: controller.player, isZoomToFill: isZoomToFill) { layer in
                        controller.attachPiP(layer: layer)
                    }
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) { location in
                        if location.x < geo.size.width * 0.38 {
                            triggerSeek(forward: false)
                        } else if location.x > geo.size.width * 0.62 {
                            triggerSeek(forward: true)
                        } else {
                            toggleControls()
                        }
                    }
                    .onTapGesture(count: 1) {
                        toggleControls()
                    }
                    .simultaneousGesture(holdToSpeedGesture)
                    .gesture(
                        MagnificationGesture()
                            .onEnded { scale in
                                if scale > 1.15 && !isZoomToFill {
                                    toggleZoom()
                                } else if scale < 0.85 && isZoomToFill {
                                    toggleZoom()
                                }
                            }
                    )

                    if let forward = seekFeedback {
                        HStack {
                            if !forward {
                                VStack(spacing: 4) {
                                    Image(systemName: "gobackward.10")
                                        .font(.system(size: 30))
                                    Text("-10s")
                                        .font(DFFont.caption().bold())
                                }
                                .foregroundStyle(.white)
                                .padding(16)
                                .background(Color.black.opacity(0.65))
                                .clipShape(Circle())
                                .padding(.leading, geo.size.width * 0.15)
                                Spacer()
                            } else {
                                Spacer()
                                VStack(spacing: 4) {
                                    Image(systemName: "goforward.10")
                                        .font(.system(size: 30))
                                    Text("+10s")
                                        .font(DFFont.caption().bold())
                                }
                                .foregroundStyle(.white)
                                .padding(16)
                                .background(Color.black.opacity(0.65))
                                .clipShape(Circle())
                                .padding(.trailing, geo.size.width * 0.15)
                            }
                        }
                        .transition(.opacity)
                    }

                    if controller.isBuffering {
                        ProgressView()
                            .tint(DFColor.gold)
                            .scaleEffect(1.4)
                    }

                    if let failure = controller.failureMessage {
                        VStack(spacing: DFSpacing.lg) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundStyle(DFColor.goldDim)
                            Text(failure)
                                .font(DFFont.body())
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, DFSpacing.xxxl)

                            if embedURL != nil {
                                Button("Mở bằng trình phát Web") {
                                    useEmbedPlayer = true
                                }
                                .font(DFFont.callout())
                                .foregroundStyle(DFColor.bg)
                                .padding(.horizontal, DFSpacing.xl)
                                .padding(.vertical, DFSpacing.md)
                                .background(DFColor.gold)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }

                if showControls && !isEmbedMode {
                    overlayControls(safeArea: geo.safeAreaInsets)
                }

                if isHoldingToSpeedUp {
                    VStack {
                        HStack(spacing: 6) {
                            Image(systemName: "forward.fill")
                                .font(.caption.bold())
                            Text("Tốc độ 2×")
                                .font(DFFont.caption().bold())
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.8))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(DFColor.gold.opacity(0.85), lineWidth: 1.2))
                        .shadow(color: .black.opacity(0.6), radius: 8, y: 3)
                        .padding(.top, max(16, geo.safeAreaInsets.top))
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
                }

                if let zoom = zoomFeedback {
                    VStack {
                        HStack(spacing: 6) {
                            Image(systemName: isZoomToFill ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                .font(.caption.bold())
                            Text(zoom)
                                .font(DFFont.caption().bold())
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.8))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(DFColor.gold.opacity(0.85), lineWidth: 1.2))
                        .shadow(color: .black.opacity(0.6), radius: 8, y: 3)
                        .padding(.top, max(16, geo.safeAreaInsets.top) + (isHoldingToSpeedUp ? 44 : 0))
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(99)
                }
            }
        }
        .statusBarHidden(true)
        .onAppear {
            OrientationManager.setOrientation(.landscapeRight)
            play(episode)
            recordWatchHistory()
            startAutoSave()
        }
        .onDisappear {
            OrientationManager.setOrientation(.portrait)
            saveResumeTime(force: true)
            controller.cleanup()
            autoHideTask?.cancel()
            autoSaveTask?.cancel()
        }
    }

    // MARK: - Overlay Controls

    private func overlayControls(safeArea: EdgeInsets) -> some View {
        VStack {
            topBar(safeArea: safeArea)
                .background(
                    LinearGradient(
                        colors: [.black.opacity(0.85), .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )

            Spacer()

            if !isEmbedMode {
                centerControls
                Spacer()
                bottomBar(safeArea: safeArea)
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.85)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }
        }
        .transition(.opacity)
        .onAppear { scheduleAutoHide() }
    }

    private func topBar(safeArea: EdgeInsets) -> some View {
        HStack(spacing: DFSpacing.lg) {
            Button {
                OrientationManager.setOrientation(.portrait)
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.white)
                    .font(.title2)
                    .padding(8)
                    .background(Color.black.opacity(0.45))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(movie.name)
                    .font(DFFont.headline())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("\(episode.name) · \(server.displayName)")
                    .font(DFFont.small())
                    .foregroundStyle(DFColor.gold)
            }

            Spacer()

            if !isEmbedMode {
                Button {
                    toggleZoom()
                } label: {
                    Image(systemName: isZoomToFill ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .foregroundStyle(.white)
                        .font(.title3)
                }

                if controller.isPiPPossible {
                    Button { controller.togglePiP() } label: {
                        Image(systemName: "pip.enter")
                            .foregroundStyle(.white)
                            .font(.title3)
                    }
                }
                AirPlayButton()
                    .frame(width: 30, height: 30)
                Menu {
                    Section("Tốc độ") { speedMenu }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.white)
                        .font(.title3)
                }
            } else {
                episodePicker
            }
        }
        .padding(.leading, max(safeArea.leading, 24))
        .padding(.trailing, max(safeArea.trailing, 24))
        .padding(.top, max(12, safeArea.top))
    }

    // MARK: - Center Controls (Play/Pause, Seek)

    private var centerControls: some View {
        HStack(spacing: 44) {
            Button {
                triggerSeek(forward: false)
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
            }

            Button {
                controller.togglePlay()
                scheduleAutoHide()
            } label: {
                Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(DFColor.gold)
            }

            Button {
                triggerSeek(forward: true)
            } label: {
                Image(systemName: "goforward.10")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Bottom Bar (Timeline, Scrubber, Episodes, Subtitles)

    private func bottomBar(safeArea: EdgeInsets) -> some View {
        VStack(spacing: DFSpacing.sm) {
            timelineBar
            HStack {
                Text(formatTime(controller.currentTime))
                    .font(DFFont.small())
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: DFSpacing.xl) {
                    if nextEpisode != nil {
                        Button {
                            if let next = nextEpisode { switchEpisode(next) }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "forward.end.fill")
                                Text("Tập tiếp")
                                    .font(DFFont.caption())
                            }
                            .foregroundStyle(.white)
                        }
                    }
                    episodePicker
                    subtitleMenu
                    audioMenu
                }
                Spacer()
                Text(formatTime(controller.duration))
                    .font(DFFont.small())
                    .foregroundStyle(DFColor.textMuted)
            }
        }
        .padding(.leading, max(safeArea.leading, 24))
        .padding(.trailing, max(safeArea.trailing, 24))
        .padding(.bottom, max(12, safeArea.bottom))
    }

    private var timelineBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)

                // Progress track
                Capsule()
                    .fill(DFColor.gold)
                    .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(controller.progress))), height: 4)

                // Scrubber thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 14, height: 14)
                    .shadow(radius: 2)
                    .offset(x: max(0, min(geo.size.width - 14, (geo.size.width * CGFloat(controller.progress)) - 7)))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        let percent = max(0, min(1, val.location.x / geo.size.width))
                        controller.seek(to: Double(percent) * controller.duration)
                    }
                    .onEnded { _ in
                        scheduleAutoHide()
                    }
            )
        }
        .frame(height: 18)
    }

    private var episodePicker: some View {
        Menu {
            ForEach(allEpisodes) { ep in
                Button {
                    switchEpisode(ep)
                } label: {
                    HStack {
                        Text(ep.name)
                        if ep.id == episode.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "list.bullet")
                Text("Chọn tập")
                    .font(DFFont.caption())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.5))
            .clipShape(Capsule())
        }
    }

    private var speedMenu: some View {
        ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { rate in
            Button {
                controller.setRate(Float(rate))
            } label: {
                HStack {
                    Text("\(rate, specifier: "%.2f")x")
                    if abs(Double(controller.rate) - rate) < 0.01 {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }

    private var subtitleMenu: some View {
        Menu {
            Button("Tắt") { controller.select(nil, for: .legible) }
            ForEach(controller.options(for: .legible).indices, id: \.self) { idx in
                let opt = controller.options(for: .legible)[idx]
                Button { controller.select(opt, for: .legible) } label: {
                    Text(opt.displayName)
                }
            }
        } label: {
            Image(systemName: "captions.bubble")
                .foregroundStyle(.white)
        }
    }

    private var audioMenu: some View {
        Menu {
            ForEach(controller.options(for: .audible).indices, id: \.self) { idx in
                let opt = controller.options(for: .audible)[idx]
                Button { controller.select(opt, for: .audible) } label: {
                    Text(opt.displayName)
                }
            }
        } label: {
            Image(systemName: "speaker.wave.2")
                .foregroundStyle(.white)
        }
    }

    // MARK: - Actions

    private func toggleZoom() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isZoomToFill.toggle()
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        zoomFeedback = isZoomToFill ? "Lấp đầy màn hình (Zoom to Fill)" : "Chuẩn tỉ lệ (Fit to Screen)"
        zoomFeedbackTask?.cancel()
        zoomFeedbackTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                zoomFeedback = nil
            }
        }
    }

    private func triggerSeek(forward: Bool) {
        controller.seekRelative(forward ? 10 : -10)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        seekFeedback = forward
        seekFeedbackTask?.cancel()
        seekFeedbackTask = Task {
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                seekFeedback = nil
            }
        }
    }

    private var holdToSpeedGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.25)
            .onEnded { _ in
                guard controller.isPlaying else { return }
                originalRate = controller.rate
                isHoldingToSpeedUp = true
                controller.setRate(2.0)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onEnded { _ in
                if isHoldingToSpeedUp {
                    isHoldingToSpeedUp = false
                    controller.setRate(originalRate)
                }
            }
    }

    private var serverIndex: Int {
        SourceServer.allCases.firstIndex(of: server) ?? 0
    }

    private func play(_ ep: Episode) {
        if isEmbedMode { return }
        guard let raw = ep.linkM3U8 ?? ep.linkEmbed, let rawURL = URL(string: raw) else {
            useEmbedPlayer = true
            return
        }
        let resume = ep.id == episode.id ? state.localStore.resumeTime(for: movie.slug) : 0

        Task {
            let streamURL = await StreamResolver.resolve(url: rawURL)
            await MainActor.run {
                controller.load(url: streamURL, startAt: resume)
            }
        }
    }

    private func switchEpisode(_ ep: Episode) {
        saveResumeTime(force: true)
        episode = ep
        play(ep)
        recordWatchHistory()
        scheduleAutoHide()
    }

    private func recordWatchHistory(seconds: Double? = nil, duration: Double? = nil) {
        let epIdx = currentIndex
        let watched = seconds ?? (isEmbedMode ? 0 : controller.currentTime)
        let totalDuration = duration ?? (isEmbedMode ? 0 : controller.duration)
        let item = HistoryItem(
            movie: movie,
            episode: episode,
            server: server.rawValue,
            serverIdx: serverIndex,
            epIndex: epIdx,
            watchedSeconds: watched,
            durationSeconds: totalDuration
        )
        state.localStore.addToHistory(item)
        if watched > 5 {
            state.localStore.setResumeTime(watched, for: movie.slug)
        }
        Task { await state.cloudSync.sync() }
    }

    private func saveResumeTime(force: Bool = false) {
        if isEmbedMode {
            recordWatchHistory()
            return
        }
        if force || controller.currentTime > 0 {
            recordWatchHistory(seconds: controller.currentTime, duration: controller.duration)
        }
    }

    private func startAutoSave() {
        autoSaveTask?.cancel()
        autoSaveTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                saveResumeTime()
                controller.updateNowPlaying(title: episode.name, subtitle: movie.name)
            }
        }
    }

    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.2)) { showControls.toggle() }
        if showControls { scheduleAutoHide() }
    }

    private func scheduleAutoHide() {
        autoHideTask?.cancel()
        autoHideTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            withAnimation { showControls = false }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

private struct VideoPlayerRepresentable: UIViewRepresentable {
    let player: AVPlayer
    let isZoomToFill: Bool
    let onLayerReady: (AVPlayerLayer) -> Void

    func makeUIView(context: Context) -> PlayerUIView {
        let v = PlayerUIView()
        v.playerLayer.player = player
        v.playerLayer.videoGravity = isZoomToFill ? .resizeAspectFill : .resizeAspect
        onLayerReady(v.playerLayer)
        return v
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
        uiView.playerLayer.videoGravity = isZoomToFill ? .resizeAspectFill : .resizeAspect
    }
}

private class PlayerUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        playerLayer.videoGravity = .resizeAspect
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .black
        playerLayer.videoGravity = .resizeAspect
    }
}

/// Embed player for Server 3 (NguonC) and web stream sources
private struct EmbedPlayerRepresentable: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsPictureInPictureMediaPlayback = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = false

        let scriptSource = """
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.getElementsByTagName('head')[0].appendChild(meta);

            var style = document.createElement('style');
            style.innerHTML = 'html, body { margin:0 !important; padding:0 !important; width:100% !important; height:100% !important; background:#000 !important; overflow:hidden !important; } #player, .jwplayer, iframe, video { width:100% !important; height:100% !important; max-width:100% !important; max-height:100% !important; }';
            document.head.appendChild(style);
        """
        let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        config.userContentController.addUserScript(userScript)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        webView.scrollView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        var request = URLRequest(url: url)
        request.setValue("https://phim.nguonc.com/", forHTTPHeaderField: "Referer")
        request.setValue("https://dragonfilm.pages.dev/", forHTTPHeaderField: "Origin")
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
            var request = URLRequest(url: url)
            request.setValue("https://phim.nguonc.com/", forHTTPHeaderField: "Referer")
            request.setValue("https://dragonfilm.pages.dev/", forHTTPHeaderField: "Origin")
            uiView.load(request)
        }
    }
}

/// `AVRoutePickerView` has no SwiftUI equivalent.
private struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.tintColor = .white
        view.activeTintColor = UIColor(DFColor.gold)
        view.prioritizesVideoDevices = true
        return view
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
