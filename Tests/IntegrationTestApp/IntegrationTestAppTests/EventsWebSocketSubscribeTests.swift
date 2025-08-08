//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Combine
import AWSAppSyncEvents

class EventsWebSocketSubscribeTests: IntegrationTestBase {
    
    private let appSyncChannelSubscriptionLimit = 200
    
    override func tearDown() async throws {
        await AuthSignInHelper.signOut()
    }
    
    // MARK: - Single event
    
    /// - Given: An events API set up with API Key authorization
    /// - When: A channel is subscribed and single event is sent to the channel
    /// - Then: The subscription should receive event
    func testSubscribeAndReceiveSingleEventSuccessAPIKey() async throws {
        guard let events = events,
              let _ = endpointURL,
              let apiKeyAuthorizer = apiKeyAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let restClient = events.createRestClient(publishAuthorizer: apiKeyAuthorizer)
        let websocketClient = events.createWebSocketClient(
            connectAuthorizer: apiKeyAuthorizer,
            publishAuthorizer: apiKeyAuthorizer,
            subscribeAuthorizer: apiKeyAuthorizer)
        let subscribeReceiveExpectation = expectation(description: "Subscription should receive events")
        let subscription = try websocketClient.subscribe(channelName: defaultChannel)
        let event = JSONValue(stringLiteral: "123")
        do {
            let task = Task {
                for try await message in subscription {
                    XCTAssertEqual(message, event)
                    subscribeReceiveExpectation.fulfill()
                    break
                }
            }
            
            // let the subscription establish
            try await Task.sleep(seconds: 5)
            
            let result = try await restClient.publish(
                channelName: defaultChannel,
                event: event)
            guard case PublishResultStatus.success = result.status else {
                XCTFail("Publish should succeed")
                return
            }
            
            await fulfillment(of: [subscribeReceiveExpectation], timeout: timeoutInSeconds)
            task.cancel()
        } catch {
            XCTFail("Operations should succeed")
        }
        
        try await websocketClient.disconnect()
    }
    
    /// - Given: An events API set up with Cognito User Pool authorization
    /// - When: A channel is subscribed and single event is sent to the channel
    /// - Then: The subscription should receive event
    func testSubscribeAndReceiveSingleEventSuccessAuthToken() async throws {
        guard let events = events,
              let _ = endpointURL,
              let authTokenAuthorizer = authTokenAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        try await signIn()
        
        let restClient = events.createRestClient(publishAuthorizer: authTokenAuthorizer)
        let websocketClient = events.createWebSocketClient(
            connectAuthorizer: authTokenAuthorizer,
            publishAuthorizer: authTokenAuthorizer,
            subscribeAuthorizer: authTokenAuthorizer)
        let subscribeReceiveExpectation = expectation(description: "Subscription should receive events")
        let subscription = try websocketClient.subscribe(channelName: defaultChannel)
        let event = JSONValue(stringLiteral: "123")
        do {
            let task = Task {
                for try await message in subscription {
                    XCTAssertEqual(message, event)
                    subscribeReceiveExpectation.fulfill()
                    break
                }
            }
            
            // let the subscription establish
            try await Task.sleep(seconds: 5)
            
            let result = try await restClient.publish(
                channelName: defaultChannel,
                event: event)
            guard case PublishResultStatus.success = result.status else {
                XCTFail("Publish should succeed")
                return
            }
            
            await fulfillment(of: [subscribeReceiveExpectation], timeout: timeoutInSeconds)
            task.cancel()
        } catch {
            XCTFail("Operations should succeed")
        }
        
        try await websocketClient.disconnect()
    }
    
    /// - Given: An events API set up with IAM Unauthenticated Role
    /// - When: A channel is subscribed and single event is sent to the channel
    /// - Then: The subscription should receive event
    func testSubscribeAndReceiveSingleEventSuccessIAMUnAuth() async throws {
        guard let events = events,
              let _ = endpointURL,
              let iamAuthorizer = iamAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let restClient = events.createRestClient(publishAuthorizer: iamAuthorizer)
        let websocketClient = events.createWebSocketClient(
            connectAuthorizer: iamAuthorizer,
            publishAuthorizer: iamAuthorizer,
            subscribeAuthorizer: iamAuthorizer)
        let subscribeReceiveExpectation = expectation(description: "Subscription should receive events")
        let subscription = try websocketClient.subscribe(channelName: defaultChannel)
        let event = JSONValue(stringLiteral: "123")
        do {
            let task = Task {
                for try await message in subscription {
                    XCTAssertEqual(message, event)
                    subscribeReceiveExpectation.fulfill()
                    break
                }
            }
            
            // let the subscription establish
            try await Task.sleep(seconds: 5)
            
            let result = try await restClient.publish(
                channelName: defaultChannel,
                event: "123")
            guard case PublishResultStatus.success = result.status else {
                XCTFail("Publish should succeed")
                return
            }
            
            await fulfillment(of: [subscribeReceiveExpectation], timeout: timeoutInSeconds)
            task.cancel()
        } catch {
            XCTFail("Operations should succeed")
        }
        
        try await websocketClient.disconnect()
    }
    
    /// - Given: An events API set up with IAM Authenticated Role
    /// - When: A channel is subscribed and single event is sent to the channel
    /// - Then: The subscription should receive event
    func testSubscribeAndReceiveSingleEventSuccessIAMAuth() async throws {
        guard let events = events,
              let _ = endpointURL,
              let iamAuthorizer = iamAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        try await signIn()
        
        let restClient = events.createRestClient(publishAuthorizer: iamAuthorizer)
        let websocketClient = events.createWebSocketClient(
            connectAuthorizer: iamAuthorizer,
            publishAuthorizer: iamAuthorizer,
            subscribeAuthorizer: iamAuthorizer)
        let subscribeReceiveExpectation = expectation(description: "Subscription should receive events")
        let subscription = try websocketClient.subscribe(channelName: defaultChannel)
        let event = JSONValue(stringLiteral: "123")
        do {
            let task = Task {
                for try await message in subscription {
                    XCTAssertEqual(message, event)
                    subscribeReceiveExpectation.fulfill()
                    break
                }
            }
            
            // let the subscription establish
            try await Task.sleep(seconds: 5)
            
            let result = try await restClient.publish(
                channelName: defaultChannel,
                event: event)
            guard case PublishResultStatus.success = result.status else {
                XCTFail("Publish should succeed")
                return
            }
            
            await fulfillment(of: [subscribeReceiveExpectation], timeout: timeoutInSeconds)
            task.cancel()
        } catch {
            XCTFail("Operations should succeed")
        }
        
        try await websocketClient.disconnect()
    }
    
    // MARK: - Multiple events
    
    /// - Given: An events API set up with API Key authorization
    /// - When: A channel is subscribed and multiple events are sent to the channel
    /// - Then: The subscription should receive all events
    func testSubscribeAndReceiveMultipleEventSuccessAPIKey() async throws {
        guard let events = events,
              let _ = endpointURL,
              let apiKeyAuthorizer = apiKeyAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let restClient = events.createRestClient(publishAuthorizer: apiKeyAuthorizer)
        let websocketClient = events.createWebSocketClient(
            connectAuthorizer: apiKeyAuthorizer,
            publishAuthorizer: apiKeyAuthorizer,
            subscribeAuthorizer: apiKeyAuthorizer)
        let subscription = try websocketClient.subscribe(channelName: defaultChannel)
        let eventsList = [
            JSONValue(stringLiteral: "123"),
            JSONValue(booleanLiteral: true),
            JSONValue(floatLiteral: 1.25),
            JSONValue(integerLiteral: 37),
            JSONValue(dictionaryLiteral: ("key", "value"))
        ]
        let subscribeReceiveExpectation = expectation(description: "Subscription should receive events")
        subscribeReceiveExpectation.expectedFulfillmentCount = eventsList.count
        do {
            let task = Task {
                for try await message in subscription {
                    if(eventsList.contains(message)) {
                        subscribeReceiveExpectation.fulfill()
                    }
                }
            }
            
            // let the subscription establish
            try await Task.sleep(seconds: 5)
            
            let result = try await restClient.publish(
                channelName: defaultChannel,
                events: eventsList)
            guard case PublishResultStatus.success = result.status else {
                XCTFail("Publish should succeed")
                return
            }
            
            await fulfillment(of: [subscribeReceiveExpectation], timeout: timeoutInSeconds)
            task.cancel()
        } catch {
            XCTFail("Operations should succeed")
        }
        
        try await websocketClient.disconnect()
    }
    
    /// - Given: An events API set up with Cognito User Pool authorization
    /// - When: A channel is subscribed and multiple events are sent to the channel
    /// - Then: The subscription should receive all events
    func testSubscribeAndReceiveMultipleEventSuccessAuthToken() async throws {
        guard let events = events,
              let _ = endpointURL,
              let authTokenAuthorizer = authTokenAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        try await signIn()
        
        let restClient = events.createRestClient(publishAuthorizer: authTokenAuthorizer)
        let websocketClient = events.createWebSocketClient(
            connectAuthorizer: authTokenAuthorizer,
            publishAuthorizer: authTokenAuthorizer,
            subscribeAuthorizer: authTokenAuthorizer)
        let subscription = try websocketClient.subscribe(channelName: defaultChannel)
        let eventsList = [
            JSONValue(stringLiteral: "123"),
            JSONValue(booleanLiteral: true),
            JSONValue(floatLiteral: 1.25),
            JSONValue(integerLiteral: 37),
            JSONValue(dictionaryLiteral: ("key", "value"))
        ]
        let subscribeReceiveExpectation = expectation(description: "Subscription should receive events")
        subscribeReceiveExpectation.expectedFulfillmentCount = eventsList.count
        do {
            let task = Task {
                for try await message in subscription {
                    if(eventsList.contains(message)) {
                        subscribeReceiveExpectation.fulfill()
                    }
                }
            }
            
            // let the subscription establish
            try await Task.sleep(seconds: 5)
            
            let result = try await restClient.publish(
                channelName: defaultChannel,
                events: eventsList)
            guard case PublishResultStatus.success = result.status else {
                XCTFail("Publish should succeed")
                return
            }
            
            await fulfillment(of: [subscribeReceiveExpectation], timeout: timeoutInSeconds)
            task.cancel()
        } catch {
            XCTFail("Operations should succeed")
        }
        
        try await websocketClient.disconnect()
    }
    
    /// - Given: An events API set up with IAM Unauthenticated role
    /// - When: A channel is subscribed and multiple events are sent to the channel
    /// - Then: The subscription should receive all events
    func testSubscribeAndReceiveMultipleEventSuccessIAMUnAuth() async throws {
        guard let events = events,
              let _ = endpointURL,
              let iamAuthorizer = iamAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        try await signIn()
        
        let restClient = events.createRestClient(publishAuthorizer: iamAuthorizer)
        let websocketClient = events.createWebSocketClient(
            connectAuthorizer: iamAuthorizer,
            publishAuthorizer: iamAuthorizer,
            subscribeAuthorizer: iamAuthorizer)
        let subscription = try websocketClient.subscribe(channelName: defaultChannel)
        let eventsList = [
            JSONValue(stringLiteral: "123"),
            JSONValue(booleanLiteral: true),
            JSONValue(floatLiteral: 1.25),
            JSONValue(integerLiteral: 37),
            JSONValue(dictionaryLiteral: ("key", "value"))
        ]
        let subscribeReceiveExpectation = expectation(description: "Subscription should receive events")
        subscribeReceiveExpectation.expectedFulfillmentCount = eventsList.count
        do {
            let task = Task {
                for try await message in subscription {
                    if(eventsList.contains(message)) {
                        subscribeReceiveExpectation.fulfill()
                    }
                }
            }
            
            // let the subscription establish
            try await Task.sleep(seconds: 5)
            
            let result = try await restClient.publish(
                channelName: defaultChannel,
                events: eventsList)
            guard case PublishResultStatus.success = result.status else {
                XCTFail("Publish should succeed")
                return
            }
            
            await fulfillment(of: [subscribeReceiveExpectation], timeout: timeoutInSeconds)
            task.cancel()
        } catch {
            XCTFail("Operations should succeed")
        }
        
        try await websocketClient.disconnect()
    }
    
    /// - Given: An events API set up with IAM Authenticated role
    /// - When: A channel is subscribed and multiple events are sent to the channel
    /// - Then: The subscription should receive all events
    func testSubscribeAndReceiveMultipleEventSuccessIAMAuth() async throws {
        guard let events = events,
              let _ = endpointURL,
              let iamAuthorizer = iamAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        try await signIn()
        
        let restClient = events.createRestClient(publishAuthorizer: iamAuthorizer)
        let websocketClient = events.createWebSocketClient(
            connectAuthorizer: iamAuthorizer,
            publishAuthorizer: iamAuthorizer,
            subscribeAuthorizer: iamAuthorizer)
        let subscription = try websocketClient.subscribe(channelName: defaultChannel)
        let eventsList = [
            JSONValue(stringLiteral: "123"),
            JSONValue(booleanLiteral: true),
            JSONValue(floatLiteral: 1.25),
            JSONValue(integerLiteral: 37),
            JSONValue(dictionaryLiteral: ("key", "value"))
        ]
        let subscribeReceiveExpectation = expectation(description: "Subscription should receive events")
        subscribeReceiveExpectation.expectedFulfillmentCount = eventsList.count
        do {
            let task = Task {
                for try await message in subscription {
                    if(eventsList.contains(message)) {
                        subscribeReceiveExpectation.fulfill()
                    }
                }
            }
            
            // let the subscription establish
            try await Task.sleep(seconds: 5)
            
            let result = try await restClient.publish(
                channelName: defaultChannel,
                events: eventsList)
            guard case PublishResultStatus.success = result.status else {
                XCTFail("Publish should succeed")
                return
            }
            
            await fulfillment(of: [subscribeReceiveExpectation], timeout: timeoutInSeconds)
            task.cancel()
        } catch {
            XCTFail("Operations should succeed")
        }
        
        try await websocketClient.disconnect()
    }
    
    // MARK: - Disconnect
    
    /// - Given: An events API set up with appropriate authorization
    /// - When: When disconnect is called after publish/subscribe call
    /// - Then: The operation should succeed
    func testDisconnectSuccessWithFlushEventsTrue() async throws {
        guard let events = events,
              let _ = endpointURL,
              let apiKeyAuthorizer = apiKeyAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let websocketClient = events.createWebSocketClient(
            connectAuthorizer: apiKeyAuthorizer,
            publishAuthorizer: apiKeyAuthorizer,
            subscribeAuthorizer: apiKeyAuthorizer)
        
        let task = Task {
            let subscription = try websocketClient.subscribe(channelName: defaultChannel)
            for try await _ in subscription {
                
            }
        }
        
        // let the subscription establish
        try await Task.sleep(seconds: 5)
        
        let disconnectSuccessExpectation = expectation(description: "Disconnect should succeed")
        do {
            try await websocketClient.disconnect(flushEvents: true)
            disconnectSuccessExpectation.fulfill()
        } catch {
            XCTFail("Disconnect should succeed")
        }
        
        await fulfillment(of: [disconnectSuccessExpectation], timeout: timeoutInSeconds)
        task.cancel()
    }
    
    /// - Given: An events API set up with appropriate authorization
    /// - When: When disconnect is called after publish/subscribe call
    /// - Then: The operation should succeed
    func testDisconnectSuccessWithFlushEventsFalse() async throws {
        guard let events = events,
              let _ = endpointURL,
              let apiKeyAuthorizer = apiKeyAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let websocketClient = events.createWebSocketClient(
            connectAuthorizer: apiKeyAuthorizer,
            publishAuthorizer: apiKeyAuthorizer,
            subscribeAuthorizer: apiKeyAuthorizer)
        
        let task = Task {
            let subscription = try websocketClient.subscribe(channelName: defaultChannel)
            for try await _ in subscription {
                
            }
        }
        
        // let the subscription establish
        try await Task.sleep(seconds: 5)
        
        let disconnectSuccessExpectation = expectation(description: "Disconnect should succeed")
        do {
            try await websocketClient.disconnect(flushEvents: false)
            disconnectSuccessExpectation.fulfill()
        } catch {
            XCTFail("Disconnect should succeed")
        }
        
        await fulfillment(of: [disconnectSuccessExpectation], timeout: timeoutInSeconds)
        task.cancel()
    }
    
    /// - Given: An events API set up with appropriate authorization
    /// - When: When disconnect is called before any publish/subscribe call
    /// - Then: The operation should throw an error
    func testDisconnectBeforeConnectFailure() async throws {
        guard let events = events,
              let _ = endpointURL,
              let apiKeyAuthorizer = apiKeyAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let websocketClient = events.createWebSocketClient(
            connectAuthorizer: apiKeyAuthorizer,
            publishAuthorizer: apiKeyAuthorizer,
            subscribeAuthorizer: apiKeyAuthorizer)
        
        let disconnectFailureExpectation = expectation(description: "Disconnect should not succeed")
        let task = Task {
            do {
                try await websocketClient.disconnect()
            } catch {
                guard case EventsError.unknown(_, _) = error else {
                    XCTFail("Error should be of type .unknown")
                    return
                }
                disconnectFailureExpectation.fulfill()
            }
        }
        
        await fulfillment(of: [disconnectFailureExpectation], timeout: timeoutInSeconds)
        
        task.cancel()
    }
    
    // MARK: - Failure scenarios
    
    /// - Given: An events API set up with appropriate authorization
    /// - When: Number of channel subscribed are > appsync limit (200)
    /// - Then: The subscriptions should fail for subscriptions made after the limit is reached
    func testAppSyncChannelSubscriptionLimitFailure() async throws {
        guard let events = events,
              let _ = endpointURL,
              let apiKeyAuthorizer = apiKeyAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let websocketClient = events.createWebSocketClient(
            connectAuthorizer: apiKeyAuthorizer,
            publishAuthorizer: apiKeyAuthorizer,
            subscribeAuthorizer: apiKeyAuthorizer)
        var tasks = [AnyCancellable]()
        
        let subscribeSuccessExpectation = expectation(description: "Subscribe success")
        subscribeSuccessExpectation.expectedFulfillmentCount = appSyncChannelSubscriptionLimit
        
        let subscribeFailureExpectation = expectation(description: "Subscribe failure")
        subscribeFailureExpectation.expectedFulfillmentCount = 5
        
        for _ in 0 ..< appSyncChannelSubscriptionLimit + 5 {
            let task = Task {
                do {
                    let subscription = try websocketClient.subscribe(channelName: defaultChannel)
                    for try await _ in subscription {
                        
                    }
                    
                    // on task cancellation, subscription sequence will end
                    subscribeSuccessExpectation.fulfill()
                } catch {
                    subscribeFailureExpectation.fulfill()
                }
            }
            tasks.append(task.toAnyCancellable)
        }

        await fulfillment(of: [subscribeFailureExpectation], timeout: timeoutInSeconds)
        
        // cancel tasks
        for task in tasks {
            task.cancel()
        }
        
        await fulfillment(of: [subscribeSuccessExpectation], timeout: timeoutInSeconds)
        try await websocketClient.disconnect()
    }
    
    /// - Given: An events API set up with appropriate authorization
    /// - When: A channel with segment containing > 50 characters is subscribed
    /// - Then: The operation should fail
    func testChannelSegmentCharacterLimitPublishFailure() async throws {
        guard let events = events,
              let _ = endpointURL,
              let apiKeyAuthorizer = apiKeyAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let channelName = "default/channel123456789123456789123456789123456789123456789123456789"
        let websocketClient = events.createWebSocketClient(
            connectAuthorizer: apiKeyAuthorizer,
            publishAuthorizer: apiKeyAuthorizer,
            subscribeAuthorizer: apiKeyAuthorizer)
        do {
            let subscription = try websocketClient.subscribe(channelName: channelName)
            for try await _ in subscription {
                XCTFail("Subscription should not be established.")
            }
            XCTFail("Subscription should not be established.")
        } catch {
            XCTAssertNotNil(error)
            guard case EventsError.service(_, _, _, _) = error else {
                XCTFail("Error should be of type .service")
                return
            }
        }
        
        try await websocketClient.disconnect()
    }
    
    /// - Given: An events API set up with appropriate authorization
    /// - When: A channel with > 5 segment is subscribed
    /// - Then: The operation should fail
    func testChannelSegmentCountLimitPublishFailure() async throws {
        guard let events = events,
              let _ = endpointURL,
              let apiKeyAuthorizer = apiKeyAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let channelName = "default/1/2/3/4/5"
        let websocketClient = events.createWebSocketClient(
            connectAuthorizer: apiKeyAuthorizer,
            publishAuthorizer: apiKeyAuthorizer,
            subscribeAuthorizer: apiKeyAuthorizer)
        do {
            let subscription = try websocketClient.subscribe(channelName: channelName)
            for try await _ in subscription {
                XCTFail("Subscription should not be established.")
            }
            XCTFail("Subscription should not be established.")
        } catch {
            XCTAssertNotNil(error)
            guard case EventsError.service(_, _, _, _) = error else {
                XCTFail("Error should be of type .service")
                return
            }
        }
        
        try await websocketClient.disconnect()
    }
    
    /// - Given: An events API set up with appropriate authorization
    /// - When: A channel with undefined namespace is subscribed
    /// - Then: The operation should fail
    func testUndefinedNamespacePublishFailure() async throws {
        guard let events = events,
              let _ = endpointURL,
              let apiKeyAuthorizer = apiKeyAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let channelName = "new/channel"
        let websocketClient = events.createWebSocketClient(
            connectAuthorizer: apiKeyAuthorizer,
            publishAuthorizer: apiKeyAuthorizer,
            subscribeAuthorizer: apiKeyAuthorizer)
        do {
            let subscription = try websocketClient.subscribe(channelName: channelName)
            for try await _ in subscription {
                XCTFail("Subscription should not be established.")
            }
            XCTFail("Subscription should not be established.")
        } catch {
            XCTAssertNotNil(error)
            guard case EventsError.service(_, _, _, _) = error else {
                XCTFail("Error should be of type .service")
                return
            }
        }
        
        try await websocketClient.disconnect()
    }
}
