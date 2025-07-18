//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


/// `AppSyncAuthorizer` implementation for using auth tokens for authorization with AppSync. You can use this class to
/// authorize requests with Cognito User Pools, OIDC, or Lambda-based custom authorization.
public class AuthTokenAuthorizer: AppSyncAuthorizer {

    private let fetchLatestAuthToken: () async throws -> String

    private static let authorizationHeaderName = "authorization"
    private static let amzDateHeaderName = "x-amz-date"
    private static let AWSDateISO8601DateFormat = "yyyyMMdd'T'HHmmss'Z'"

    private lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = AuthTokenAuthorizer.AWSDateISO8601DateFormat
        return formatter
    }()

    /// - Parameters:
    ///     - fetchLatestAuthToken: Closure which returns a valid auth token.
    public init(fetchLatestAuthToken: @escaping () async throws -> String) {
        self.fetchLatestAuthToken = fetchLatestAuthToken
    }

    public func getAuthorizationHeaders(request: URLRequest) async throws -> [String: String] {
        let date = formatter.string(from: Date())
        let token = try await fetchLatestAuthToken()
        return [
            AuthTokenAuthorizer.amzDateHeaderName: date,
            AuthTokenAuthorizer.authorizationHeaderName: token
        ]
    }
}
