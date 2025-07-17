//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSAppSyncEvents
import Foundation

class MockAPIKeyAuthorizer: APIKeyAuthorizer {
    var isInvoked: Bool = false
    
    override init(apiKey: String) {
        super.init(apiKey: apiKey)
    }
    
    override func getAuthorizationHeaders(request: URLRequest) async throws -> [String : String] {
        isInvoked = true
        return try await super.getAuthorizationHeaders(request: request)
    }
    
}
