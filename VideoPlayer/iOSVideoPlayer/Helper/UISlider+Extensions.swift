//
//  UISlider+Extensions.swift
//  iOSVideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/23.
//

import UIKit

extension UISlider {
    public func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }

    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self)
        let percent = minimumValue + Float(location.x / bounds.width) * maximumValue
        setValue(percent, animated: false)
        sendActions(for: .valueChanged)
    }
}
