//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation


/// Implement this protocol to add prepend interceptors before REST call is made or
/// Websocket connection is established
/// Pass it in `RestOptions` or `WebSocketOptions` before creating a client
public protocol URLRequestInterceptor {
    func intercept(_ request: URLRequest) async throws -> URLRequest
}
