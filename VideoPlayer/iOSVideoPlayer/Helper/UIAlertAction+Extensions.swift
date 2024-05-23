//
//  UIAlertAction+Extensions.swift
//  iOSVideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/20.
//

import UIKit

extension UIAlertAction {
    static func cancel(_ title: String? = nil, handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        return UIAlertAction(title: title, style: .cancel, handler: handler)
    }
}
