//
//  Configurable.swift
//  iOSVideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/20.
//

import Foundation

protocol Configurable {}

extension NSObject: Configurable {}

extension Configurable where Self: AnyObject {
    @discardableResult
    func configure(_ transform: (Self) -> Void) -> Self {
        transform(self)
        return self
    }
}
