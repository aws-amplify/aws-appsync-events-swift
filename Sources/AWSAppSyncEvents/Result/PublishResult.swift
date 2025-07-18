//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Result type of an event(s) publish call
/// - successfulEvents: list of events successfully processed by AWS AppSync.
/// - failedEvents: list of events that AWS AppSync failed to process.
/// Check index under `successfulEvents` and `failedEvents` list
/// to determine individual results.
public struct PublishResult: Codable {
    public let successfulEvents: [SuccessfulEvent]
    public let failedEvents: [FailedEvent]

    public var status: PublishResultStatus {
        if successfulEvents.count > 0 && failedEvents.count > 0 {
            return .partialSuccess
        }
        
        if failedEvents.count > 0 {
            return .failure
        }
        
        return .success
    }
    
    enum CodingKeys: String, CodingKey {
        case successfulEvents = "successful"
        case failedEvents = "failed"
    }
}


/// Represents a successful response, which may contain both successful and failed events.
/// A `.success` case indicates the publish itself succeeded, not that all events were processed successfully.
/// - `.success`: All events published successfully
/// - `.failure`: All events failed to publish
/// - `.partialSuccess`: mix of successful and failed events.
public enum PublishResultStatus {
    case success
    case failure
    case partialSuccess
}

/// Contains identifying information of a successfully processed event.
/// - identifier: identifier of event used for logging purposes.
/// - index: index of the event as it was sent in the publish call
public struct SuccessfulEvent: Codable {
    let identifier: String
    let index: Int
}


/// Contains identifying information of an event AWS AppSync failed to process.
/// - identifier: identifier of event used for logging purposes.
/// - index: index of the event as it was sent in the publish call
/// - errorCode: error codefor the failed event.
/// - errorMessage: error message for the failed event.
public struct FailedEvent: Codable {
    let identifier: String
    let index: Int
    let errorCode: Int?
    let errorMessage: String?
}
