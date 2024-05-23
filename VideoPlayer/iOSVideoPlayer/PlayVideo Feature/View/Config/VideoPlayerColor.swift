//
//  VideoPlayerColor.swift
//  iOSVideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/23.
//

import UIKit

struct VideoPlayerColor: Equatable {
    
    enum VideoPlayerColorPalatte: String, CaseIterable, Equatable {
        case white
        case pearlWhite
        case black
        case red

        var uiColor: UIColor { UIColor(named: self.rawValue) ?? UIColor() }
    }
    
    private let palette: VideoPlayerColorPalatte
    private let alpha: CGFloat

    init(palette: VideoPlayerColorPalatte, alpha: CGFloat = 1.0) {
        self.palette = palette
        self.alpha = alpha
    }

    var uiColor: UIColor { palette.uiColor.withAlphaComponent(alpha) }
}
