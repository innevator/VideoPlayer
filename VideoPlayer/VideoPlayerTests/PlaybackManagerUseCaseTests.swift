//
//  PlaybackManagerUseCaseTests.swift
//  VideoPlayerTests
//
//  Created by 洪宗鴻 on 2024/5/30.
//

import XCTest
import VideoPlayer
import AVFoundation

class PlaybackManagerUseCaseTests: XCTestCase {
    
    func test_initailize() {
        let client = HTTPClientSpy()
        let playbackManager = PlaybackManager(client: client)
        
        XCTAssertNil(playbackManager.stream)
    }
    
    func test_delegations() {
        let expPlayerReadyToPlay = expectation(description: "expect playerReadyToPlay trigger")
        let expPlayerFinishPlaying = expectation(description: "expect playerFinishPlaying trigger")
        let client = HTTPClientSpy()
        let playbackManager = PlaybackManager(client: client)
        var testPlayers: [AVPlayer] = []
        var testTimes: [CMTime] = []
        var getPlaybackQualitiesTimes: [Int] = []
        
        playbackManager.playerReadyToPlay = { player in
            testPlayers.append(player)
            expPlayerReadyToPlay.fulfill()
        }
        playbackManager.playerPeriodicTimeChange = { time in
            testTimes.append(time)
        }
        playbackManager.playerFinishPlaying = {
            expPlayerFinishPlaying.fulfill()
        }
        playbackManager.getPlaybackQualities = { _ in
            getPlaybackQualitiesTimes.append(1)
        }
        
        playbackManager.stream = Stream.test
        client.complete(with: NSError(domain: "", code: 0))
        
        wait(for: [expPlayerReadyToPlay], timeout: 10)
        
        XCTAssertEqual(testPlayers.count, 1)
        
        let player = testPlayers.first
        guard let duration = player?.currentItem?.duration else {
            XCTFail("can't get playItem duration")
            return
        }
        player?.play()
        player?.seek(to: duration, toleranceBefore: .zero, toleranceAfter: .zero)
        
        wait(for: [expPlayerFinishPlaying], timeout: 10)
        
        XCTAssertTrue(testTimes.count > 0)
        XCTAssertEqual(getPlaybackQualitiesTimes, [1])
    }
}

private extension VideoPlayer.Stream {
    static let test = Stream(id: UUID().uuidString, name: "test steam", url: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8")
}
