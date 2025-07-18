//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSAppSyncEvents
import Foundation

class MockURLSessionBehavior : URLSessionBehavior {
    
    private let type: MockURLSessionBehavior.ResultType
    
    init(type: MockURLSessionBehavior.ResultType) {
        self.type = type
    }
    
    enum ResultType {
        case failure
        case success
        case successWithPublishFailure
        case successWithPublishPartialSuccess
    }
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        switch type {
        case .failure:
            return (
                Data(),
                HTTPURLResponse.init(
                    url: URL(string: "https://example.com")!,
                    statusCode: 400,
                    httpVersion: nil,
                    headerFields: nil)!
            )
        case .success:
            return (
                String("""
                       {
                         "id": "dummyId",
                         "successful": [
                           {
                             "identifier": "id-1",
                             "index": 0
                           }
                         ],
                         "failed": []
                       }
                """).data(using: .utf8)!,
                HTTPURLResponse.init(
                    url: URL(string: "https://example.com")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil)!
            )
        case .successWithPublishFailure:
            return (
                String("""
                       {
                         "id": "dummyId",
                         "successful": [],
                         "failed": [
                           {
                             "identifier": "id-1",
                             "index": 0
                           }
                         ]
                       }
                """).data(using: .utf8)!,
                HTTPURLResponse.init(
                    url: URL(string: "https://example.com")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil)!
            )
        case .successWithPublishPartialSuccess:
            return (
                String("""
                       {
                         "id": "dummyId",
                         "successful": [
                           {
                             "identifier": "id-1",
                             "index": 0
                           }
                         ],
                         "failed": [
                           {
                             "identifier": "id-1",
                             "index": 0
                           }
                         ]
                       }
                """).data(using: .utf8)!,
                HTTPURLResponse.init(
                    url: URL(string: "https://example.com")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil)!
            )
        }
    }
    
    func finishTasksAndInvalidate() {
        // do nothing
    }
    
    
}
