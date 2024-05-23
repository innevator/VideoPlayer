//
//  XCTestCase+MemoryLeakTracking.swift
//  VideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/16.
//

import XCTest

extension XCTestCase {
	func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
		addTeardownBlock { [weak instance] in
			XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
		}
	}
}
