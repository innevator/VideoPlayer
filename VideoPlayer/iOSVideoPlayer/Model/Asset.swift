//
//  Asset.swift
//  VideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/16.
//

import VideoPlayer

/*
 a type for adaption Stream from VideoPlayer SDK
 */

class Asset {
    private let stream: VideoPlayer.Stream
    
    var name: String { return stream.name }
    
    init(stream: VideoPlayer.Stream) {
        self.stream = stream
    }
    
    func getStream() -> VideoPlayer.Stream {
        return stream
    }
}
