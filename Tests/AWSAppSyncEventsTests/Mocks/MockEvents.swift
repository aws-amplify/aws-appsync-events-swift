//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSAppSyncEvents
import Foundation

class MockEvents: EventsBehavior {
    private let endpointURL: URL
    private let urlSessionBehavior: URLSessionBehavior
    
    init(endpointURL: URL,
         urlSessionBehavior: URLSessionBehavior) {
        self.endpointURL = endpointURL
        self.urlSessionBehavior = urlSessionBehavior
    }
    
    func createRestClient(
        publishAuthorizer: any AWSAppSyncEvents.AppSyncAuthorizer,
        options: AWSAppSyncEvents.Events.RestOptions
    ) -> any AWSAppSyncEvents.RestClientBehavior {
        return EventsRestClient(
            endpointURL: endpointURL,
            publishAuthorizer: publishAuthorizer,
            urlSessionBehavior: urlSessionBehavior,
            options: options)
    }
    
    func createWebSocketClient(
        connectAuthorizer: any AWSAppSyncEvents.AppSyncAuthorizer,
        publishAuthorizer: any AWSAppSyncEvents.AppSyncAuthorizer,
        subscribeAuthorizer: any AWSAppSyncEvents.AppSyncAuthorizer,
        options: AWSAppSyncEvents.Events.WebSocketOptions
    ) -> any AWSAppSyncEvents.WebSocketClientBehavior {
        return EventsWebSocketClient(
            endpointURL: endpointURL,
            connectAuthorizer: connectAuthorizer,
            publishAuthorizer: publishAuthorizer,
            subscribeAuthorizer: subscribeAuthorizer,
            options: options)
    }
}
