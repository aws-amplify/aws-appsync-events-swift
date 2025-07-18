//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `AppSyncAuthorizer` implementation that uses IAM policies for authorization. This authorizer delegates to the
/// `getAuthorizationHeaders` function to generate a signature to add to each request.
/// The signature generation should use AWS SigV4 signing. There is an implementation of this signing logic in the
/// amplify-swift library, or you can use the AWS SDK for Swift, or any other SigV4 implementation.
public class IAMAuthorizer: AppSyncAuthorizer {
    private let signRequest: (_ urlRequest: URLRequest) async throws -> URLRequest
    
    /// - Parameters
    ///     - request: `signRequest` closure that performs the signing. It should return all of the SigV4 headers
    /// necessary for a signed request.
    public init(signRequest: @escaping (URLRequest) async throws -> URLRequest) {
        self.signRequest = signRequest
    }

    public func getAuthorizationHeaders(request: URLRequest) async throws -> [String: String] {
        let signedRequest = try await signRequest(request)
        return signedRequest.allHTTPHeaderFields ?? [:]
    }
}
