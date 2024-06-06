//
//  AssetService.swift
//  iOSVideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/17.
//

import Foundation
import VideoPlayer

/*
 use for mock remote API request to get assets data
 */

class MockHttpClient: HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        guard let data = try? Data(contentsOf: url) else {
            completion(.failure(Error.readDataFailed))
            return
        }
        completion(.success((data, HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!)))
    }
    
    enum Error: Swift.Error {
        case readDataFailed
    }
}

class AssetService {
    private lazy var loader: StreamLoader = {
        let url = Bundle.main.url(forResource: "Streams", withExtension: "json")!
        return RemoteStreamLoader(url: url, client: MockHttpClient())
    }()
    
    convenience init(loader: StreamLoader) {
        self.init()
        self.loader = loader
    }
    
    func getAssets(completion: @escaping (Result<[Asset], Error>) -> Void) {
        loader.load { result in
            switch result {
            case .success(let streams):
                completion(.success(streams.map { return Asset(stream: $0)}))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
