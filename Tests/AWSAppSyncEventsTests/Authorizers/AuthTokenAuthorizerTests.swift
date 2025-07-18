//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSAppSyncEvents
import XCTest

final class AuthTokenAuthorizerTests: XCTestCase {
    static let endpoint = URL(string: "https://abc.appsync-api.us-east-1.amazonaws.com/event")!
    static let urlRequest = URLRequest(url: endpoint)
    let authorizer = AuthTokenAuthorizer { "token" }

    func testGetAuthorizationHeaders() async throws {
        let headers = try await authorizer.getAuthorizationHeaders(request: APIKeyAuthorizerTests.urlRequest)
        XCTAssertEqual(headers.count, 2)
        XCTAssertEqual(headers["authorization"], "token")
        XCTAssertTrue(headers["x-amz-date"] != nil)
    }
}
