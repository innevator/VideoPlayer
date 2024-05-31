//
//  Quality.swift
//  iOSVideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/31.
//

import Foundation
import VideoPlayer

/*
 a type for adaption VideoQuality from VideoPlayer SDK
 */

struct Quality {
    let bitrate: Double
    let resolution: String
    
    init(videoQuality: VideoQuality) {
        self.bitrate = videoQuality.bitrate
        self.resolution = videoQuality.resolution
    }
}
