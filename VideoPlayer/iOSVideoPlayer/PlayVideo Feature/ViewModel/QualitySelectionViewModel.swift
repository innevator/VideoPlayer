//
//  QualitySelectionViewModel.swift
//  iOSVideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/24.
//

import Foundation

class QualitySelectionViewModel {
    var supportedQualities: [Quality]
    var selectedItemIndex: Int = 0

    init(supportedQualities: [Quality]) {
        self.supportedQualities = supportedQualities
    }
}
