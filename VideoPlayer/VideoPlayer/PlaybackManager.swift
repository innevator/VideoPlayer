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
    private var playerItemObserver: NSKeyValueObservation?
    private var urlAssetObserver: NSKeyValueObservation?
    private var periodicTimeObserver: Any?
    private var playerItem: AVPlayerItem? {
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
    public var stream: Stream? {
        willSet {
            guard let urlAssetObserver = urlAssetObserver else { return }
            urlAssetObserver.invalidate()
        }
        didSet {
            if let stream = stream, let url = URL(string: stream.url) {
                let urlAsset = AVURLAsset(url: url)
                urlAssetObserver = urlAsset.observe(\AVURLAsset.isPlayable, options: [.new, .initial]) { [weak self] (urlAsset, _) in
                    guard let self = self, urlAsset.isPlayable == true else { return }
                    
                    self.playerItem = AVPlayerItem(asset: urlAsset)
                    self.player.replaceCurrentItem(with: self.playerItem)
                    self.fetchSupportedVideoQualites(url: url) { [weak self] qualities in
                        self?.getPlaybackQualities(qualities)
                    }
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
    
    override public init() {
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
    
    
    // MARK: - Video Quality
    
    private func fetchSupportedVideoQualites(url: URL, completions: @escaping ([VideoQuality]) -> Void) {
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
            if let data = data {
                let playbackQualities = M3u8Helper().fetchSupportedVideoQualities(with: data)
                completions(playbackQualities)
            }
            else {
                completions([])
            }
        }
        task.resume()
    }
}
