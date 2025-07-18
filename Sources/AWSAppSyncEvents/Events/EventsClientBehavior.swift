//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

protocol RestClientBehavior {
    func publish(
        channelName: String,
        event: JSONValue,
        authorizer: AppSyncAuthorizer?) async throws -> PublishResult
    
    func publish(
        channelName: String,
        events: [JSONValue],
        authorizer: AppSyncAuthorizer?) async throws -> PublishResult
}

protocol WebSocketClientBehavior {
    func publish(
        channelName: String,
        event: JSONValue,
        authorizer: AppSyncAuthorizer?) async throws -> PublishResult
    
    func publish(
        channelName: String,
        events: [JSONValue],
        authorizer: AppSyncAuthorizer?) async throws -> PublishResult
    
    func subscribe(channelName:String,
                   authorizer: AppSyncAuthorizer?) throws -> AsyncThrowingStream<JSONValue, Error>
    
    func disconnect(flushEvents: Bool) async throws
}
