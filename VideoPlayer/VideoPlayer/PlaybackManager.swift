//
//  PlaybackManager.swift
//  VideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/16.
//

import AVFoundation

public class PlaybackManager: NSObject {
    
    // MARK: Properties
    
    private let player = AVPlayer()
    private let client: HTTPClient
    private var playerItemObserver: NSKeyValueObservation?
    private var urlAssetObserver: NSKeyValueObservation?
    private var periodicTimeObserver: Any?
    public private(set) var playerItem: AVPlayerItem? {
        willSet {
            guard let playerItemObserver = playerItemObserver else { return }
            playerItemObserver.invalidate()
        }
        
        didSet {
            playerItemObserver = playerItem?.observe(\AVPlayerItem.status, options: [.new, .initial]) { [weak self] (item, _) in
                guard let self = self else { return }
                if item.status == .readyToPlay {
                    self.playerReadyToPlay(self.player)
                } else if item.status == .failed {
                    print("Error: \(String(describing:  item.error?.localizedDescription))")
                }
            }
        }
    }
    public private(set) var stream: Stream? {
        willSet {
            guard let urlAssetObserver = urlAssetObserver else { return }
            urlAssetObserver.invalidate()
        }
        didSet {
            if let stream = stream, let url = URL(string: stream.url) {
                fetchSupportedVideoQualites(url: url)
                let urlAsset = AVURLAsset(url: url)
                urlAssetObserver = urlAsset.observe(\AVURLAsset.isPlayable, options: [.new, .initial]) { [weak self] (urlAsset, _) in
                    guard let self = self, urlAsset.isPlayable == true else { return }
                    
                    self.playerItem = AVPlayerItem(asset: urlAsset)
                    self.player.replaceCurrentItem(with: self.playerItem)
                }
            } else {
                playerItem = nil
                player.replaceCurrentItem(with: nil)
            }
        }
    }
    
    public var supportedLanguages: [AVMediaSelectionOption]? {
        guard let mediaSelectionGroup = playerItem?.asset.mediaSelectionGroup(forMediaCharacteristic: .legible)
        else { return nil }
        return mediaSelectionGroup.options.filter { $0.extendedLanguageTag != nil }
    }
    
    public private(set) var supportedQualities: [VideoQuality] = [] {
        didSet {
           getPlaybackQualities(supportedQualities)
        }
    }
    
    // MARK: - Delegation
    
    public var playerReadyToPlay: (_ player: AVPlayer) -> () = { _ in
        print("[PlaybackManager] playerReadyToPlay has not been implemented")
    }
    public var playerPeriodicTimeChange: (_ time: CMTime) -> () = { _ in
        print("[PlaybackManager] playerPeriodicTimeChange has not been implemented")
    }
    public var playerFinishPlaying: () -> () = {
        print("[PlaybackManager] playerDidFinishPlaying has not been implemented")
    }
    public var getPlaybackQualities: ([VideoQuality]) -> () = { _ in
        print("[PlaybackManager] getPlaybackQualities has not been implemented")
    }
    
    // MARK: Intitialization
    
    public init(client: HTTPClient) {
        self.client = client
        super.init()
        
        #if os(iOS)
        player.allowsExternalPlayback = true
        player.usesExternalPlaybackWhileExternalScreenIsActive = true
        #endif
        
        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        periodicTimeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            if self.player.currentItem?.status == .readyToPlay {
                self.playerPeriodicTimeChange(time)
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    deinit {
        if let periodicTimeObserver = periodicTimeObserver {
            player.removeTimeObserver(periodicTimeObserver)
        }
        periodicTimeObserver = nil
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    
    // MARK: - Playback Functions
    
    @objc func playerDidFinishPlaying() {
        playerFinishPlaying()
    }
    
    public func pause() {
        player.pause()
    }
    
    public func play() {
        player.play()
    }
    
    public func seekToTime(_ time: CMTime, completion: @escaping (Bool) -> Void) {
        guard let duration = player.currentItem?.duration
        else { return }
        let seekToTime = time.seconds < CMTimeGetSeconds(duration) ? CMTimeMake(value: Int64(time.seconds * 1000 as Float64), timescale: 1000) : CMTimeMake(value: Int64(CMTimeGetSeconds(duration) * 1000 as Float64), timescale: 1000)
        player.seek(to: seekToTime, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: completion)
    }
                    
    public func seekWithOffest(_ value: CGFloat, completion: @escaping (CMTime) -> Void) {
        guard let duration = player.currentItem?.duration
        else { return }
        let playerCurrentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = playerCurrentTime + value
        let seekToTime = newTime < CMTimeGetSeconds(duration) ? CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000) : CMTimeMake(value: Int64(CMTimeGetSeconds(duration) * 1000 as Float64), timescale: 1000)
        player.seek(to: seekToTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            guard let self = self,
                  let currentTime = player.currentItem?.currentTime()
            else { return }
            completion(currentTime)
        }
    }
    
    public func setSubTitleTrack(_ subtitleTrack: AVMediaSelectionOption?) {
        guard let playerItem = player.currentItem,
              let mediaSelectionGroup = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: .legible)
        else { return }
        playerItem.select(subtitleTrack, in: mediaSelectionGroup)
    }
    
    public func setStreamBitrate(_ bitrate: Double) {
        playerItem?.preferredPeakBitRate = bitrate
    }
    
    public func setStream(_ stream: Stream?) {
        self.stream = stream
    }
    
    // MARK: - Video Quality
    
    private func fetchSupportedVideoQualites(url: URL) {
        client.get(from: url) { [weak self] result in
            switch result {
            case .success(let (data, _)):
                let playbackQualities = M3u8Helper().fetchSupportedVideoQualities(with: data)
                self?.supportedQualities = playbackQualities
            case .failure(_):
                self?.supportedQualities = []
            }
        }
    }
}
