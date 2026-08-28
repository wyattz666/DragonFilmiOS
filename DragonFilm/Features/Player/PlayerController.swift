import SwiftUI
import AVKit
import MediaPlayer
import AVFoundation

/// Owns the AVPlayer and republishes the bits SwiftUI needs. A periodic time
/// observer drives the scrubber; without it the UI has no way to learn that
/// playback advanced.
@Observable
final class PlayerController: NSObject, AVPictureInPictureControllerDelegate {
    var currentTime: Double = 0
    var duration: Double = 0
    var isPlaying = false
    var rate: Float = 1.0
    var isBuffering = true
    var failureMessage: String?
    var isPiPActive = false

    var progress: Double {
        duration > 0 ? max(0, min(1, currentTime / duration)) : 0
    }

    private(set) var player = AVPlayer()
    private var timeObserver: Any?
    private var statusTask: Task<Void, Never>?
    private var pipController: AVPictureInPictureController?

    func cleanup() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        statusTask?.cancel()
    }

    override init() {
        super.init()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        player.allowsExternalPlayback = true

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            currentTime = time.seconds.isFinite ? time.seconds : 0
            if let item = player.currentItem {
                let d = item.duration.seconds
                duration = d.isFinite && d > 0 ? d : 0
                isBuffering = !item.isPlaybackLikelyToKeepUp && player.timeControlStatus != .playing
            }
            isPlaying = player.timeControlStatus == .playing
        }
    }

    deinit {
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        statusTask?.cancel()
    }

    func load(url: URL, startAt seconds: Double) {
        failureMessage = nil
        isBuffering = true
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        if seconds > 5 {
            player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
        }
        player.playImmediately(atRate: rate)

        statusTask?.cancel()
        statusTask = Task { [weak self] in
            // AVPlayerItem reports load failure asynchronously; surface it so the
            // UI can offer a different server instead of spinning forever.
            for await status in item.publisher(for: \.status).values {
                guard !Task.isCancelled else { return }
                if status == .failed {
                    self?.failureMessage = item.error?.localizedDescription
                        ?? "Không phát được nguồn này. Thử đổi server."
                    self?.isBuffering = false
                    return
                }
                if status == .readyToPlay {
                    self?.isBuffering = false
                }
            }
        }
    }

    func togglePlay() {
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.playImmediately(atRate: rate)
        }
        isPlaying = player.timeControlStatus == .playing
    }

    func setRate(_ newRate: Float) {
        rate = newRate
        if player.timeControlStatus == .playing {
            player.rate = newRate
        }
    }

    func seek(to seconds: Double) {
        let clamped = max(0, min(seconds, duration > 0 ? duration : seconds))
        player.seek(to: CMTime(seconds: clamped, preferredTimescale: 600))
        currentTime = clamped
    }

    func seekRelative(_ delta: Double) {
        seek(to: currentTime + delta)
    }

    func pause() { player.pause() }

    // MARK: - Picture in Picture

    /// `AVPictureInPictureController` needs an `AVPlayerLayer` that is already in
    /// a view hierarchy, so `PlayerView` hands its layer over once it exists.
    func attachPiP(layer: AVPlayerLayer) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        let controller = AVPictureInPictureController(playerLayer: layer)
        controller?.delegate = self
        pipController = controller
    }

    var isPiPPossible: Bool { pipController?.isPictureInPicturePossible ?? false }

    func togglePiP() {
        guard let pipController else { return }
        if pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
        } else {
            pipController.startPictureInPicture()
        }
    }

    private func setupPiP() {
        // The controller is created in `attachPiP` once a player layer exists.
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ controller: AVPictureInPictureController) {
        isPiPActive = true
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        isPiPActive = false
    }

    /// Populates the lock-screen / control-centre now-playing panel.
    func updateNowPlaying(title: String, subtitle: String) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: subtitle,
            MPNowPlayingInfoPropertyPlaybackRate: player.rate
        ]
        if duration > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = duration
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    /// Tracks the HLS stream exposes, for the subtitle and audio pickers.
    func options(for characteristic: AVMediaCharacteristic) -> [AVMediaSelectionOption] {
        guard let asset = player.currentItem?.asset,
              let group = asset.mediaSelectionGroup(forMediaCharacteristic: characteristic)
        else { return [] }
        return group.options
    }

    func select(_ option: AVMediaSelectionOption?, for characteristic: AVMediaCharacteristic) {
        guard let item = player.currentItem,
              let group = item.asset.mediaSelectionGroup(forMediaCharacteristic: characteristic)
        else { return }
        item.select(option, in: group)
    }

    func selectedOption(for characteristic: AVMediaCharacteristic) -> AVMediaSelectionOption? {
        guard let item = player.currentItem,
              let group = item.asset.mediaSelectionGroup(forMediaCharacteristic: characteristic)
        else { return nil }
        return item.currentMediaSelection.selectedMediaOption(in: group)
    }
}
