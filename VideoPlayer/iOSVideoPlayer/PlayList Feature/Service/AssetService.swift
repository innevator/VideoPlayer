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
    func getAssets(completion: @escaping (Result<[Asset], Error>) -> Void) {
        let url = Bundle.main.url(forResource: "Streams", withExtension: "json")!
        let loader = RemoteStreamLoader(url: url, client: MockHttpClient())
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
