//
//  Stream.swift
//  VideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/16.
//

import Foundation

public class Stream: Codable {
    
    // MARK: Properties
    
    public let id: String
    public let name: String
    public let url: String
    
    
    // MARK: Initializer
    
    public init(id: String, name: String, url: String) {
        self.id = id
        self.name = name
        self.url = url
    }
    
    
    // MARK: CodingKeys
    
    private enum CodingKeys: String, CodingKey {
        case id = "stream_id"
        case name = "stream_name"
        case url = "stream_url"
    }
}

extension Stream: Equatable {
    public static func ==(lhs: Stream, rhs: Stream) -> Bool {
        return (lhs.name == rhs.name) && (lhs.url == rhs.url)
    }
}
