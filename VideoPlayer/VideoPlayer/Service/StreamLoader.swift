//
//  StreamLoader.swift
//  VideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/16.
//

import Foundation

public protocol StreamLoader {
    typealias Result = Swift.Result<[Stream], Error>

    func load(completion: @escaping (Result) -> Void)
}

