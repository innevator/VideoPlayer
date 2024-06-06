//
//  UIViewController+Helpers.swift
//  iOSVideoPlayerTests
//
//  Created by 洪宗鴻 on 2024/6/6.
//

import UIKit

extension UIViewController {
    func simulateAppearance() {
        if !isViewLoaded {
            loadViewIfNeeded()
        }

        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }
}
