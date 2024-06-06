//
//  PlaybackManagerUseCaseTests.swift
//  VideoPlayerTests
//
//  Created by 洪宗鴻 on 2024/5/30.
//

import XCTest
import VideoPlayer

class PlaybackManagerUseCaseTests: XCTestCase {
    
    weak var playbackManager: PlaybackManager?
    
    override func tearDown() {
        super.tearDown()
        
        XCTAssertNil(playbackManager, "memory leak detect")
    }
    
    func test_initailize() {
        let (sut, _) = makeSUT()
        XCTAssertNil(sut.stream)
    }
    
    func test_readyToPlayWhenStreamSetup() {
        let exp = expectation(description: "expect playerReadyToPlay")
        let (sut, _) = makeSUT()
        sut.playerReadyToPlay = { _ in
            exp.fulfill()
        }
        
        sut.setStream(.test)
        
        wait(for: [exp], timeout: 5)
    }
    
    func test_periodicTimeChangeWhenPlaying() {
        let exp = expectation(description: "expect periodicTimeChange")
        let (sut, _) = makeSUT()
        sut.playerReadyToPlay = { [weak sut] _ in
            sut?.seekWithOffest(5, completion: { _ in })
        }
        sut.playerPeriodicTimeChange = { time in
            exp.fulfill()
        }
        
        sut.setStream(.test)
        
        wait(for: [exp], timeout: 5)
    }
    
    func test_playerFinishPlaying() {
        let exp = expectation(description: "expect playerFinishPlaying")
        let (sut, _) = makeSUT()
        sut.playerReadyToPlay = { [weak sut] player in
            guard let duration = player.currentItem?.duration else {
                XCTFail("playerItem has no duration")
                return
            }
            sut?.seekToTime(duration, completion: { _ in
                sut?.play()
            })
        }
        sut.playerFinishPlaying = {
            exp.fulfill()
        }
        
        sut.setStream(.test)
        
        wait(for: [exp], timeout: 5)
    }
    
    func test_getPlaybackQualitiesWhenStreamSetup() {
        let exp = expectation(description: "expect getPlaybackQualities")
        let (sut, client) = makeSUT()
        sut.getPlaybackQualities = { _ in
            exp.fulfill()
        }
        
        sut.setStream(.test)
        client.complete(with: NSError(domain: "", code: 0))
        
        wait(for: [exp], timeout: 1)
    }
    
    func test_playerSeekingTimeWithOffest() {
        let exp = expectation(description: "expect seekingTime")
        let (sut, _) = makeSUT()
        sut.playerReadyToPlay = { [weak sut] player in
            sut?.seekWithOffest(1, completion: { _ in
                exp.fulfill()
            })
        }
        
        sut.setStream(.test)
        
        wait(for: [exp], timeout: 5)
    }
    
    // MARK: - Helper
    
    private func makeSUT() -> (PlaybackManager, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let playbackManager = PlaybackManager(client: client)
        self.playbackManager = playbackManager
        return (playbackManager, client)
    }
}

private extension VideoPlayer.Stream {
    static let test = Stream(id: UUID().uuidString, name: "test steam", url: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8")
}
