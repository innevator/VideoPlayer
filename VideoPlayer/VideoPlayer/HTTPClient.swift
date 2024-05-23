//
//  HTTPClient.swift
//  VideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/16.
//

import Foundation

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>

    func get(from url: URL, completion: @escaping (Result) -> Void)
}
