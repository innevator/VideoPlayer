//
//  PlayVideoViewModel.swift
//  iOSVideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/22.
//

import Foundation
import CoreMedia
import VideoPlayer
import AVFoundation
import UIKit

// MARK: - Constant Setting

private let seekDuration: Float64 = 15
private let controlHideDelay: TimeInterval = 3.0

class PlayVideoViewModel {
    
    enum PlayerState {
        case playing, pause
        
        mutating func toggle() {
            switch self {
            case .playing:
                self = .pause
            case .pause:
                self = .playing
            }
        }
    }
    
    enum PlaybackIndex: Int {
        case previous = -1
        case next = 1
    }
    
    
    // MARK: - Properties
    
    private var playerState: PlayerState = .pause {
        didSet {
            updatePlayerState(playerState)
        }
    }
    private let assets: [Asset]
    private var controlsHiddenTimer: Timer?
    private let playbackManager = PlaybackManager(client: URLSessionClient())
    private(set) var currentPlayback: Asset? {
        didSet {
            playbackManager.stream = currentPlayback?.getStream()
            guard let currentPlayback = currentPlayback else { return }
            changePlayback(currentPlayback)
        }
    }
    private var currentPlaybackIndex = 0
    var hasPreviousPlayback: Bool {
        return currentPlaybackIndex + PlaybackIndex.previous.rawValue >= 0
    }
    var hasNextPlayback: Bool {
        return currentPlaybackIndex + PlaybackIndex.next.rawValue <= assets.count - 1
    }
    
    var supportedLanguages: [AVMediaSelectionOption] {
        return playbackManager.supportedLanguages ?? []
    }
    
    var supportedQualities: [Quality] {
        return playbackManager.supportedQualities.map { Quality(videoQuality: $0) }
    }
    
    
    // MARK: - Delegation
    
    var hideControls: (() -> ()) = {
        print("[PlayVideoViewModel] hideControls has not implemented")
    }
    
    var changePlayback: ((Asset) -> ()) = { _ in
        print("[PlayVideoViewModel] changePlayback has not implemented")
    }
    
    var changePeriodTime: ((CMTime) -> ()) = { _ in
        print("[PlayVideoViewModel] changePeriodTime has not implemented")
    }
    
    var readyToPlay: ((_ player: AVPlayer, _ playerState: PlayerState) -> ()) = { _, _ in
        print("[PlayVideoViewModel] playerReadyToPlay has not implemented")
    }
    
    var updatePlayerState: ((PlayerState) -> ()) = { _ in
        print("[PlayVideoViewModel] updatePlayerState has not implemented")
    }
    
    
    // MARK: - Initializer
    
    init(assets: [Asset]) {
        self.assets = assets
    }
    
    
    // MARK: - Playback Functions
    
    func setupPlayback() {
        playbackManager.playerReadyToPlay = { [weak self] player in
            guard let self = self else { return }
            self.readyToPlay(player, self.playerState)
        }
        playbackManager.playerPeriodicTimeChange = { [weak self] time in
            guard let self = self else { return }
            self.changePeriodTime(time)
        }
        playbackManager.playerFinishPlaying = { [weak self] in
            guard let self = self else { return }
            if let duration = playbackManager.playerItem?.duration {
                self.changePeriodTime(duration)
            }
            if hasNextPlayback {
                self.changePlayback(.next)
                if self.playerState == .playing {
                    self.playbackManager.play()
                }
            }
            else {
                if self.playerState == .playing {
                    self.playbackManager.pause()
                    self.playerState = .pause
                }
            }
        }
        playbackManager.getPlaybackQualities = { _ in }
        
        let currentPlayback = assets[0]
        self.currentPlayback = currentPlayback
    }
    
    func removePlayback() {
        playbackManager.pause()
        currentPlayback = nil
    }
    
    func changePlayback(_ index: PlaybackIndex) {
        if currentPlaybackIndex + index.rawValue > assets.count - 1 || currentPlaybackIndex + index.rawValue < 0 { return }
        currentPlaybackIndex += index.rawValue
        currentPlayback = assets[currentPlaybackIndex]
    }
    
    func playerStateToggle() {
        if playerState == .playing {
            playbackManager.pause()
        }
        else {
            playbackManager.play()
            hideControls()
        }
        
        playerState.toggle()
    }
    
    func pausePlay() {
        if playerState == .playing {
            playbackManager.pause()
            updatePlayerState(.pause)
        }
    }
    
    func resumPlay() {
        if playerState == .playing {
            playbackManager.play()
            updatePlayerState(.playing)
        }
    }
    
    func seekTo(_ value: Float) {
        let time = CMTimeMake(value: Int64(value), timescale: 1)
        playbackManager.seekToTime(time) { [weak self] finish in
            self?.playerState == .playing ? self?.playbackManager.play() : self?.playbackManager.pause()
        }
    }
    
    func goForwardTime() {
        playbackManager.seekWithOffest(seekDuration) { [weak self] time in
            self?.changePeriodTime(time)
        }
    }
    
    func goBackwardTime() {
        playbackManager.seekWithOffest(-seekDuration) { [weak self] time in
            self?.changePeriodTime(time)
        }
    }
    
    func changeSubTitleTrack(_ subtitleTrack: AVMediaSelectionOption?) {
        playbackManager.setSubTitleTrack(subtitleTrack)
    }
    
    func selectStreamQuality(_ quality: Quality) {
        playbackManager.setStreamBitrate(quality.bitrate)
    }
    
    
    // MARK: - Timer Control
    
    func resetControlsHiddenTimer() {
        invalidateControlsHiddenTimer()
        controlsHiddenTimer = Timer.scheduledTimer(timeInterval: controlHideDelay,
                                                   target: self,
                                                   selector: #selector(hideControlsDueToInactivity), userInfo: nil, repeats: false)
    }
    
    func invalidateControlsHiddenTimer() {
        controlsHiddenTimer?.invalidate()
        controlsHiddenTimer = nil
    }
    
    @objc private func hideControlsDueToInactivity() {
        hideControls()
    }
}

struct Quality {
    let bitrate: Double
    let resolution: String
    
    init(videoQuality: VideoQuality) {
        self.bitrate = videoQuality.bitrate
        self.resolution = videoQuality.resolution
    }
}
