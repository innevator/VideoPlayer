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
    private var isSeeking = false
    private var player: AVPlayer? {
        didSet {
            if let player = player {
                readyToPlay(player, playerState)
            }
        }
    }
    private(set) var currentPlayback: Asset? {
        willSet { supportedQualities = [] }
        didSet {
            playbackManager.stream = currentPlayback?.getStream()
            guard let currentPlayback = currentPlayback else { return }
            changePlayback(currentPlayback)
        }
    }
    private var currentPlaybackIndex = 0
    var supportedLanguages: [AVMediaSelectionOption] {
        return playbackManager.supportedLanguages ?? []
    }
    
    var supportedQualities: [VideoQuality] = []
    private var currentQualitiyIndex = 0
    var qualitiyViewModel: QualitySelectionViewModel {
        let viewModel = QualitySelectionViewModel(supportedResolutions: supportedQualities.map(\.resolution))
        viewModel.selectedItemIndex = currentQualitiyIndex
        return viewModel
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
            self?.player = player
        }
        playbackManager.playerPeriodicTimeChange = { [weak self] time in
            guard let self = self else { return }
            if !self.isSeeking {
                self.changePeriodTime(time)
            }
        }
        playbackManager.playerFinishPlaying = { [weak self] in
            guard let self = self else { return }
            self.changePlayback(.next)
            if self.playerState == .playing {
                self.player?.play()
            }
        }
        playbackManager.getPlaybackQualities = { [weak self] qualities in
            self?.supportedQualities = qualities
        }
        
        let currentPlayback = assets[0]
        self.currentPlayback = currentPlayback
    }
    
    func removePlayback() {
        if let player = player {
            player.pause()
        }
        currentPlayback = nil
    }
    
    func changePlayback(_ index: PlaybackIndex) {
        if currentPlaybackIndex + index.rawValue > assets.count - 1 || currentPlaybackIndex + index.rawValue < 0 { return }
        currentPlaybackIndex += index.rawValue
        currentPlayback = assets[currentPlaybackIndex]
    }
    
    func playerStateToggle() {
        if playerState == .playing {
            player?.pause()
        }
        else {
            player?.play()
            hideControls()
        }
        
        playerState.toggle()
    }
    
    func pausePlay() {
        if playerState == .playing {
            player?.pause()
            updatePlayerState(.pause)
        }
        invalidateControlsHiddenTimer()
    }
    
    func resumPlay() {
        if playerState == .playing {
            player?.play()
            updatePlayerState(.playing)
        }
        resetControlsHiddenTimer()
    }
    
    func dragPeriodTime(value: Float, event: UIEvent) {
        guard let player = player else { return }
        isSeeking = true
        let time = CMTimeMake(value: Int64(value), timescale: 1)
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                player.pause()
                invalidateControlsHiddenTimer()
            case .moved:
                changePeriodTime(time)
            case .ended:
                resetControlsHiddenTimer()
                player.seek(to: time) { [weak self] _ in
                    self?.isSeeking = false
                    self?.playerState == .playing ? player.play() : player.pause()
                }
            default:
                break
            }
        }
        else {
            resetControlsHiddenTimer()
            changePeriodTime(time)
            player.seek(to: time) { [weak self] _ in
                self?.isSeeking = false
            }
        }
    }
    
    func goForwardTime() {
        guard let player = player,
              let duration = player.currentItem?.duration
        else { return }
        let playerCurrentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = playerCurrentTime + seekDuration
        let seekToTime = newTime < CMTimeGetSeconds(duration) ? CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000) : CMTimeMake(value: Int64(CMTimeGetSeconds(duration) * 1000 as Float64), timescale: 1000)
        player.seek(to: seekToTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { [weak self] _ in
            guard let self = self,
                  let currentTime = player.currentItem?.currentTime()
            else { return }
            self.changePeriodTime(currentTime)
        }
    }
    
    func goBackwardTime() {
        guard let player = player else { return }
        let playerCurrentTime = CMTimeGetSeconds(player.currentTime())
        var newTime = playerCurrentTime - seekDuration
        if newTime < 0 { newTime = 0 }
        let seekToTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
        player.seek(to: seekToTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { [weak self] _ in
            guard let self = self,
                  let currentTime = player.currentItem?.currentTime()
            else { return }
            self.changePeriodTime(currentTime)
        }
    }
    
    func changeSubTitleTrack(_ subtitleTrack: AVMediaSelectionOption?) {
        guard let playerItem = player?.currentItem,
              let mediaSelectionGroup = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: .legible)
        else { return }
        playerItem.select(subtitleTrack, in: mediaSelectionGroup)
    }
    
    func selectStreamBitrate(at index: Int) {
        let bitrate = supportedQualities[index].bitrate
        guard let playerItem = player?.currentItem else { return }
        playerItem.preferredPeakBitRate = bitrate
        self.currentQualitiyIndex = index
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
