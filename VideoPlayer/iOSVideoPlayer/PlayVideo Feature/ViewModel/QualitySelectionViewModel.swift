//
//  QualitySelectionViewModel.swift
//  iOSVideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/24.
//

import Foundation

class QualitySelectionViewModel {
    var supportedResolutions: [String]
    var selectedItemIndex: Int = 0

    init(supportedResolutions: [String]) {
        self.supportedResolutions = supportedResolutions
    }
}
