//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSAppSyncEvents
import XCTest

final class APIKeyAuthorizerTests: XCTestCase {

    let authorizer = APIKeyAuthorizer(apiKey: "apiKey")
    static let endpoint = URL(string: "https://abc.appsync-api.us-east-1.amazonaws.com/event")!
    static let urlRequest = URLRequest(url: endpoint)

    func testGetAuthorizationHeaders() async throws {
        let headers = try await authorizer.getAuthorizationHeaders(request: APIKeyAuthorizerTests.urlRequest)
        XCTAssertEqual(headers.count, 2)
        XCTAssertEqual(headers["x-api-key"], "apiKey")
        XCTAssertTrue(headers["x-amz-date"] != nil)
    }
}
