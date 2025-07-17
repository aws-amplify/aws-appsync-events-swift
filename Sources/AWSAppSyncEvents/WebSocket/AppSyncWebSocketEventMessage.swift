//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AppSyncWebSocketEventMessage : Codable {
    var id: String { get }
}

struct PublishMessage: Codable, AppSyncWebSocketEventMessage {
    let type: String
    let id: String
    let channel: String
    let events: [String]  // stringified json
    let authorization: [String: String]
}

struct PublishSuccess: Codable, AppSyncWebSocketEventMessage {
    let type: String
    let id: String
    let successful: [SuccessfulEvent]?
    let failed: [FailedEvent]?
}

struct PublishError: Codable, AppSyncWebSocketEventMessage {
    let type: String
    let id: String
    let errors: [AppSyncWebSocketError]?
}

struct SubscribeMessage: Codable, AppSyncWebSocketEventMessage {
    let type: String
    let id: String
    let channel: String
    let authorization: [String: String]
}

struct SubscribeSuccess: Codable, AppSyncWebSocketEventMessage {
    let type: String
    let id: String
}

struct SubscribeError: Codable, AppSyncWebSocketEventMessage {
    let type: String
    let id: String
    let errors: [AppSyncWebSocketError]?
}

struct SubscribeData: Codable, AppSyncWebSocketEventMessage {
    let type: String
    let id: String
    let event: String
}

struct BroadcastError: Codable, AppSyncWebSocketEventMessage {
    let type: String
    let id: String
    let errors: [AppSyncWebSocketError]?
}

struct UnsubscribeMessage: Codable, AppSyncWebSocketEventMessage {
    let type: String
    let id: String
}

struct UnsubscribeSuccess: Codable, AppSyncWebSocketEventMessage {
    let type: String
    let id: String
}

struct UnsubscribeError: Codable, AppSyncWebSocketEventMessage {
    let type: String
    let id: String
    let errors: [AppSyncWebSocketError]?
}

struct AppSyncError: Codable, AppSyncWebSocketEventMessage {
    let type: String
    let id: String
    let errors: [AppSyncWebSocketError]?
}
