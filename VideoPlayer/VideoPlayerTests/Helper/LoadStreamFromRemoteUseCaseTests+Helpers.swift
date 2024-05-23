//
//  LoadFeedFromRemoteUseCaseTests+Helpers.swift
//  VideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/16.
//

import XCTest
import VideoPlayer

extension LoadStreamFromRemoteUseCaseTests {
    func expect(_ sut: RemoteStreamLoader, toCompleteWith expectedResult: Result<[VideoPlayer.Stream], RemoteStreamLoader.Error>, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
		let exp = expectation(description: "Wait for load completion")

		sut.load { receivedResult in
			switch (receivedResult, expectedResult) {
			case let (.success(receivedItems), .success(expectedItems)):
				XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)

			case let (.failure(receivedError as RemoteStreamLoader.Error), .failure(expectedError)):
				XCTAssertEqual(receivedError, expectedError, file: file, line: line)

			default:
				XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
			}

			exp.fulfill()
		}

		action()

		waitForExpectations(timeout: 0.1)
	}
}
