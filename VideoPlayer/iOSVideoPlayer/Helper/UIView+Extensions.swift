//
//  UIView+Extensions.swift
//  iOSVideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/24.
//

import UIKit

public extension UIView {
    func roundCorners(
        corners: CACornerMask = [.layerMinXMaxYCorner,
                                 .layerMaxXMaxYCorner,
                                 .layerMinXMinYCorner,
                                 .layerMaxXMinYCorner],
        cornerRadius: CGFloat
    ) {
        layer.maskedCorners = corners
        layer.masksToBounds = true
        layer.cornerRadius = cornerRadius
    }
}
