//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The main class for interacting with AWS AppSync Events API
public final class Events : EventsBehavior {
    private let endpointURL: URL

    public init(endpointURL: URL) {
        self.endpointURL = endpointURL
    }
    
    // MARK: - Events Behavior
    
    /// Create a REST client to publish to channels over HTTP endpoint
    ///
    ///@param publishAuthorizer sets the default AppSyncAuthorizer for REST publish calls
    /// - Parameters:
    ///   - publishAuthorizer: sets the default AppSyncAuthorizer for REST publish calls
    ///   - options: for optional customizations to the REST client
    /// - Returns: REST client for HTTP publish calls
    public func createRestClient(publishAuthorizer: any AppSyncAuthorizer,
                                 options: RestOptions = .default) -> EventsRestClient {
        let configuration = options.urlSessionConfiguration ?? .default
        // set min/max tls version
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        configuration.tlsMaximumSupportedProtocolVersion = .TLSv13
        // disable caching
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        return EventsRestClient(
            endpointURL: EventsEndpointHelper.appSyncHTTPEndpoint(endpointURL),
            publishAuthorizer: publishAuthorizer,
            urlSessionBehavior: URLSession(configuration: configuration),
            options: options)
    }
    
    
    /// Create a WebSocket client to subscribe and publish to channels over WebSocket
    /// - Parameters:
    ///   - connectAuthorizer: sets the default AppSyncAuthorizer for the websocket connection
    ///   - publishAuthorizer: sets the default AppSyncAuthorizer for subscriptions over the websocket
    ///   - subscribeAuthorizer: sets the default AppSyncAuthorizer for publishes over the websocket
    ///   - options: for optional customizations to the EventsWebSocketClient
    /// - Returns: Web Socket client for making publish/subscribe calls
    public func createWebSocketClient(connectAuthorizer: any AppSyncAuthorizer,
                                      publishAuthorizer: any AppSyncAuthorizer,
                                      subscribeAuthorizer: any AppSyncAuthorizer,
                                      options: WebSocketOptions = .default) -> EventsWebSocketClient {
        return EventsWebSocketClient(endpointURL: EventsEndpointHelper.appSyncRealTimeEndpoint(endpointURL),
                                     connectAuthorizer: connectAuthorizer,
                                     publishAuthorizer: publishAuthorizer,
                                     subscribeAuthorizer: subscribeAuthorizer,
                                     options: options)
    }
    
}
