//
//  URLSessionClient.swift
//  iOSVideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/30.
//

import Foundation
import VideoPlayer

class URLSessionClient: HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
            if let data = data, let response = response as? HTTPURLResponse {
                completion(.success((data, response)))
            }
            else {
                completion(.failure(NSError(domain: "", code: 0)))
            }
        }.resume()
    }
}
