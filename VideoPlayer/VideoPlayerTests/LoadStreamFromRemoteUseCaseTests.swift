//
//  LoadStreamFromRemoteUseCaseTests+Helpers.swift
//  VideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/16.
//

import XCTest
import VideoPlayer

class LoadStreamFromRemoteUseCaseTests: XCTestCase {
	func test_init_doesNotRequestDataFromURL() {
		let (_, client) = makeSUT()

		XCTAssertTrue(client.requestedURLs.isEmpty)
	}

	func test_loadTwice_requestsDataFromURLTwice() {
		let url = URL(string: "https://a-given-url.com")!
		let (sut, client) = makeSUT(url: url)

		sut.load { _ in }
		sut.load { _ in }

		XCTAssertEqual(client.requestedURLs, [url, url])
	}

	func test_load_deliversConnectivityErrorOnClientError() {
		let (sut, client) = makeSUT()

		expect(sut, toCompleteWith: .failure(.connectivity), when: {
			let clientError = NSError(domain: "Test", code: 0)
			client.complete(with: clientError)
		})
	}

	func test_load_deliversInvalidDataErrorOnNon200HTTPResponse() {
		let (sut, client) = makeSUT()

		let samples = [199, 201, 300, 400, 500]

		samples.enumerated().forEach { index, code in
			expect(sut, toCompleteWith: .failure(.invalidData), when: {
				let json = makeItemsJSON([])
				client.complete(withStatusCode: code, data: json, at: index)
			})
		}
	}

	func test_load_deliversInvalidDataErrorOn200HTTPResponseWithInvalidJSON() {
		let (sut, client) = makeSUT()

		expect(sut, toCompleteWith: .failure(.invalidData), when: {
			let invalidJSON = Data("invalid json".utf8)
			client.complete(withStatusCode: 200, data: invalidJSON)
		})
	}

	func test_load_deliversInvalidDataErrorOn200HTTPResponseWithPartiallyValidJSONItems() {
		let (sut, client) = makeSUT()

		let validItem = makeItem(
			id: UUID(),
            url: "http://another-url.com"
		).json

		let invalidItem = ["invalid": "item"]

		let items = [validItem, invalidItem]

		expect(sut, toCompleteWith: .failure(.invalidData), when: {
			let json = makeItemsJSON(items)
			client.complete(withStatusCode: 200, data: json)
		})
	}

	func test_load_deliversSuccessWithNoItemsOn200HTTPResponseWithEmptyJSONList() {
		let (sut, client) = makeSUT()

		expect(sut, toCompleteWith: .success([]), when: {
			let emptyListJSON = makeItemsJSON([])
			client.complete(withStatusCode: 200, data: emptyListJSON)
		})
	}

	func test_load_deliversSuccessWithItemsOn200HTTPResponseWithJSONItems() {
		let (sut, client) = makeSUT()

		let item1 = makeItem(
            id: UUID(),
            url: "http://a-url.com")

		let item2 = makeItem(
			id: UUID(),
			name: "a name",
			url: "http://a-url.com")

		let items = [item1.model, item2.model]

		expect(sut, toCompleteWith: .success(items), when: {
			let json = makeItemsJSON([item1.json, item2.json])
			client.complete(withStatusCode: 200, data: json)
		})
	}

	func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
		let url = URL(string: "http://any-url.com")!
		let client = HTTPClientSpy()
		var sut: RemoteStreamLoader? = RemoteStreamLoader(url: url, client: client)

		var capturedResults = [RemoteStreamLoader.Result]()
		sut?.load { capturedResults.append($0) }

		sut = nil
		client.complete(withStatusCode: 200, data: makeItemsJSON([]))

		XCTAssertTrue(capturedResults.isEmpty)
	}

	// MARK: - Helpers

	private func makeSUT(url: URL = URL(string: "https://a-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteStreamLoader, client: HTTPClientSpy) {
		let client = HTTPClientSpy()
		let sut = RemoteStreamLoader(url: url, client: client)
		trackForMemoryLeaks(sut, file: file, line: line)
		trackForMemoryLeaks(client, file: file, line: line)
		return (sut, client)
	}

    private func makeItem(id: UUID, name: String = "", url: String = "") -> (model: VideoPlayer.Stream, json: [String: Any]) {
        let item = Stream(id: id.uuidString, name: name, url: url)

		let json = [
			"stream_id": id.uuidString,
			"stream_name": name,
			"stream_url": url
		].compactMapValues { $0 }

		return (item, json)
	}

	private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
		let json = ["items": items]
		return try! JSONSerialization.data(withJSONObject: json)
	}
}
