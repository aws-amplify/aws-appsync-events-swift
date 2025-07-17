//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `AppSyncAuthorizer` implementation that authorizes requests via API Key.
public class APIKeyAuthorizer: AppSyncAuthorizer {

    private let fetchAPIKey: () async throws -> String
    private static let apiKeyHeaderName = "x-api-key"
    private static let amzDateHeaderName = "x-amz-date"
    private static let AWSDateISO8601DateFormat = "yyyyMMdd'T'HHmmss'Z'"

    private lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = APIKeyAuthorizer.AWSDateISO8601DateFormat
        return formatter
    }()

    /// - Parameters:
    ///     - apiKey: API key configured for Events API
    public init(apiKey: String) {
        self.fetchAPIKey = {
            apiKey
        }
    }
    
    /// - Parameters:
    ///     - fetchAPIKey: a closure returning the api key
    public init(fetchAPIKey: @escaping () async throws -> String) {
        self.fetchAPIKey = fetchAPIKey
    }

    public func getAuthorizationHeaders(request: URLRequest) async throws -> [String: String] {
        let apiKey = try await fetchAPIKey()
        let date = formatter.string(from: Date())
        return [APIKeyAuthorizer.apiKeyHeaderName: apiKey,
                APIKeyAuthorizer.amzDateHeaderName: date]
    }
}
