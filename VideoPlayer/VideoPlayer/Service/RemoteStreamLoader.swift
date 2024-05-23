//
//  RemoteStreamLoader.swift
//  VideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/16.
//

import Foundation

public class RemoteStreamLoader: StreamLoader {
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    // MARK: - Properties
    
    private let url: URL
    private let client: HTTPClient
    
    
    // MARK: - Initializer
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    
    // MARK: - Functions
    
    public func load(completion: @escaping (StreamLoader.Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case .success((let data, let response)):
                if response.statusCode == 200, let root = try? JSONDecoder().decode(Root.self, from: data) {
                    completion(.success(root.items))
                } else {
                    completion(.failure(Error.invalidData))
                }
            case .failure(_):
                completion(.failure(Error.connectivity))
            }
        }
    }
    
    private struct Root: Decodable {
        let items: [Stream]
    }
}
