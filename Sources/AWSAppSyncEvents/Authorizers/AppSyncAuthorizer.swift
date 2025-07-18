//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Protocol for classes that provide different types of authorization for AppSync. AppSync supports various auth
/// modes, including API Key, Cognito User Pools, OIDC, Lambda-based authorization, and IAM policies. Implementations
/// of this interface can be used to provide the specific headers and payloads needed for the auth mode being used.
/// - Parameters:
///     - request: The `URLRequest` object required to calculate auth headers
/// - Returns:
///     - the authorization headers to be included in AppSync API calls
public protocol AppSyncAuthorizer {
    func getAuthorizationHeaders(request: URLRequest) async throws -> [String: String]
}
