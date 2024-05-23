//
//  CMTime+Extensions.swift
//  iOSVideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/22.
//

import AVFoundation
import AVKit

extension CMTime {
    var durationText: String {
        let totalSeconds = CMTimeGetSeconds(self)
        let hours = Int(totalSeconds.truncatingRemainder(dividingBy: 86400) / 3600)
        let minutes = Int(totalSeconds.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))

        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, minutes, seconds)
        }
        return String(format: "%02i:%02i", minutes, seconds)
    }
}
