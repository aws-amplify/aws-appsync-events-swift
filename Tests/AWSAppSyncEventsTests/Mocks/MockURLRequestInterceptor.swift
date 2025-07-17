//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSAppSyncEvents
import XCTest
import Foundation

class MockWebSocketURLRequestInterceptor: URLRequestInterceptor {
    
    static let mockHeaderKey = "mockHeaderKey"
    static let mockHeaderValue = "mockHeaderValue"
    
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        var mutatedRequest = request
        mutatedRequest.setValue(
            MockWebSocketURLRequestInterceptor.mockHeaderValue,
            forHTTPHeaderField: MockWebSocketURLRequestInterceptor.mockHeaderKey
        )
        return mutatedRequest
    }
    
}

class MockRestURLRequestInterceptor: URLRequestInterceptor {
    
    private let expectationToBeFulfilled: XCTestExpectation
    
    init(expectation: XCTestExpectation) {
        self.expectationToBeFulfilled = expectation
    }
    
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        expectationToBeFulfilled.fulfill()
        return request
    }
    
}


    
