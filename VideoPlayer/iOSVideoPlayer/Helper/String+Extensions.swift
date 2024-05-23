//
//  String+Extensions.swift
//  VideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/16.
//

import Foundation

extension String {
    init(_ key: LocalizedKey) {
        let formatString : String = NSLocalizedString(key.rawValue, comment: "")
        self = String.localizedStringWithFormat(formatString)
    }
}
