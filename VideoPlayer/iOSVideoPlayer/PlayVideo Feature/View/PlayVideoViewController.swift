//
//  PlayVideoViewController.swift
//  iOSVideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/17.
//

import UIKit
import AVFoundation

class PlayVideoViewController: UIViewController {
    
    
    // MARK: - Properties
    
    private let router: Router
    private let playerControlView = PlayerControlView().configure {
        $0.isPlaying = false
    }
    private let viewModel: PlayVideoViewModel
    private let activityIndicatorView = UIActivityIndicatorView().configure {
        $0.tintColor = .gray
        $0.color = .gray
        $0.hidesWhenStopped = true
    }
    private let playerLayer = AVPlayerLayer(player: nil)
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    var isPortrait: Bool {
        let orientation = UIDevice.current.orientation
        switch orientation {
        case .portrait, .portraitUpsideDown:
            return true
        case .landscapeLeft, .landscapeRight:
            return false
        default: // unknown or faceUp or faceDown
            return view.frame.size.width < view.frame.size.height
        }
    }
    private var panOffset: Double = 0
    private var qualitySelectionVC: QualitySelectionViewController?
    
    // MARK: - Initializer
    
    init(router: Router, assets: [Asset]) {
        self.router = router
        self.viewModel = PlayVideoViewModel(assets: assets)
        super.init(nibName: nil, bundle: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(enterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(enterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self,
                                    name: UIApplication.didEnterBackgroundNotification,
                                    object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                    name: UIApplication.willEnterForegroundNotification,
                                    object: nil)
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestureRecognizers()
        binding()
        
        viewModel.setupPlayback()
        
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        viewModel.invalidateControlsHiddenTimer()
        viewModel.removePlayback()
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = view.bounds
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        playerControlView.updateUI(isPortrait: isPortrait)
    }
    
    // MARK: - Functions
    
    private func binding() {
        self.viewModel.hideControls = { [weak self] in
            self?.hideControls()
        }
        self.viewModel.changePlayback = { [weak self] playback in
            guard let self = self else { return }
            self.playerControlView.titleLabelText = playback.name
            self.playerControlView.subtitleLabelText = playback.name
            self.playerControlView.seekBarValue = 0
            self.playerControlView.seekBarMaximumValue = 0
            self.playerControlView.previousVideoButtonState = self.viewModel.hasPreviousPlayback
            self.playerControlView.nextVideoButtonState = self.viewModel.hasNextPlayback
            let time = CMTime(seconds: 0, preferredTimescale: 1)
            self.playerControlView.currentTimeLabelText = time.durationText + "/"
            self.playerControlView.totalTimeLabelText = time.durationText
            self.hideControls()
            self.activityIndicatorView.startAnimating()
        }
        self.viewModel.readyToPlay = { [weak self] player, playerState in
            guard let self = self else { return }
            self.playerLayer.player = player
            if let duration = player.currentItem?.duration {
                self.playerControlView.seekBarMaximumValue = Float(duration.seconds)
                self.playerControlView.totalTimeLabelText = duration.durationText
            }
            if playerState == .pause {
                self.showControls()
            }
            self.setupSubtiteSelectionView()
            self.setupQualitySelectionView()
            self.playerControlView.seekBarValue = 0
            self.activityIndicatorView.stopAnimating()
        }
        self.viewModel.changePeriodTime = { [weak self] time in
            self?.playerControlView.seekBarValue = Float(time.seconds)
            self?.playerControlView.currentTimeLabelText = time.durationText + "/"
        }
        self.viewModel.updatePlayerState = { [weak self] playerState in
            self?.playerControlView.isPlaying = playerState == .playing
        }
    }
    
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.layer.addSublayer(playerLayer)
        
        view.addSubview(playerControlView)
        playerControlView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        playerControlView.updateUI(isPortrait: isPortrait)
        playerControlView.delegate = self
        hideControls()
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.snp.makeConstraints { make in
            make.centerY.equalTo(view.snp.centerY)
            make.centerX.equalTo(view.snp.centerX)
        }
        activityIndicatorView.startAnimating()
    }
    
    private func setupGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)
        
        tapGesture.require(toFail: doubleTapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        view.addGestureRecognizer(panGesture)
    }
    
    private func setupSubtiteSelectionView() {
        viewModel.supportedLanguages.count > 0 ?  playerControlView.showSubtitlesButton() : playerControlView.hideSubtitlesButton()
    }
    
    func setupQualitySelectionView() {
        viewModel.supportedQualities.count > 0 ? playerControlView.showSettingsButton() : playerControlView.hideSettingsButton()
    }
    
    @objc private func enterBackground() {
        viewModel.pausePlay()
    }
    
    @objc private func enterForeground() {
        viewModel.resumPlay()
    }
}


// MARK: - Show/Hide Control Functionality

extension PlayVideoViewController {
    @objc private func handleTap(_: UITapGestureRecognizer) {
        viewModel.resetControlsHiddenTimer()
        playerControlView.isHidden ? showControls() : hideControls()
    }
    
    @objc private func handleDoubleTap(tap: UITapGestureRecognizer) {
        if tap.location(in: view).x > view.frame.size.width / 2 {
            seekForward()
        }
        else {
            seekBackward()
        }
    }
   
    @objc private func handlePan(pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            panOffset = pan.translation(in: view).x
            viewModel.pausePlay()
        case .changed:
            let offset = (pan.translation(in: view).x - panOffset) / 10
            var value = playerControlView.seekBarValue + Float(offset)
            if value >= playerControlView.seekBarMaximumValue {
                value = playerControlView.seekBarMaximumValue
            }
            if value <= 0 {
                value = 0
            }
            let time = CMTimeMake(value: Int64(value), timescale: 1)
            viewModel.changePeriodTime(time)
        case .ended:
            viewModel.seekTo(playerControlView.seekBarValue)
        default:
            break
        }
    }
    
    private func showControls() {
        playerControlView.isHidden = false
        
        UIView.animate(withDuration: 0.25) {
            self.playerControlView.alpha = 1
        }
        viewModel.resetControlsHiddenTimer()
    }
    
    @objc func hideControls() {
        UIView.animate(withDuration: 0.25) {
            self.playerControlView.alpha = 0
        } completion: { _ in
            self.playerControlView.isHidden = true
        }
    }
}


// MARK: - PlayerControlsViewDelegate

extension PlayVideoViewController: PlayerControlsViewDelegate {
    func seekForward() {
        viewModel.goForwardTime()
    }
    
    func seekBackward() {
        viewModel.goBackwardTime()
    }
    
    func togglePlayPause() {
        viewModel.playerStateToggle()
    }
    
    func playPreviousVideo() {
        viewModel.changePlayback(.previous)
    }
    
    func playNextVideo() {
        viewModel.changePlayback(.next)
    }
    
    func goBack() {
        router.backToPrevious()
    }
    
    func sliderValueChanged(slider: UISlider, event: UIEvent) {
        let time = CMTimeMake(value: Int64(playerControlView.seekBarValue), timescale: 1)
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                viewModel.invalidateControlsHiddenTimer()
                viewModel.pausePlay()
            case .moved:
                viewModel.changePeriodTime(time)
            case .ended:
                viewModel.resetControlsHiddenTimer()
                viewModel.seekTo(playerControlView.seekBarValue)
            default:
                break
            }
        }
        else { // tap slider to seek, implement by extension gesture will not have touch event
            viewModel.resetControlsHiddenTimer()
            viewModel.changePeriodTime(time)
            viewModel.seekTo(playerControlView.seekBarValue)
        }
    }
    
    func switchSubtitles() {
        viewModel.invalidateControlsHiddenTimer()
        viewModel.pausePlay()
        let subtitleSelectionView = SubtitleSelectionViewController(viewModel: .init(supportedLanguages: viewModel.supportedLanguages))
        subtitleSelectionView.delegate = self
        self.navigationController?.present(subtitleSelectionView, animated: true)
    }
    
    func openSettings() {
        viewModel.invalidateControlsHiddenTimer()
        viewModel.pausePlay()
        if qualitySelectionVC == nil {
            let qualitySelectionVC = QualitySelectionViewController(viewModel: .init(supportedQualities: viewModel.supportedQualities))
            qualitySelectionVC.delegate = self
            self.qualitySelectionVC = qualitySelectionVC
        }
        self.navigationController?.present(qualitySelectionVC!, animated: true)
    }
}


// MARK: - Subtitle Functionality

extension PlayVideoViewController: SubtitleSelectionDelegate {
    func onSubtitleTrackSelected(subtitleTrack: AVMediaSelectionOption?) {
        viewModel.changeSubTitleTrack(subtitleTrack)
    }
    
    func onDismissed() {
        viewModel.resumPlay()
        viewModel.resetControlsHiddenTimer()
    }
}


// MARK: - Video Quality Settings Functionality

extension PlayVideoViewController: QualitySelectionDelegate {
    func onQualitySettingSelected(quality: Quality) {
        viewModel.selectStreamQuality(quality)
    }
}
