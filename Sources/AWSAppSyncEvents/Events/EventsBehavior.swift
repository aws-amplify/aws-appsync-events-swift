//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

protocol EventsBehavior {
    associatedtype RestClientBehavior
    associatedtype WebSocketClientBehavior
    
    func createRestClient(publishAuthorizer: AppSyncAuthorizer, options: Events.RestOptions) -> RestClientBehavior
    
    func createWebSocketClient(connectAuthorizer: AppSyncAuthorizer,
                               publishAuthorizer: AppSyncAuthorizer,
                               subscribeAuthorizer: AppSyncAuthorizer,
                               options: Events.WebSocketOptions) -> WebSocketClientBehavior
}
