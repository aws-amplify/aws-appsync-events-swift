//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Combine
@testable import AWSAppSyncEvents

class EventsWebSocketTests: XCTestCase {
    private let channelName = "/default/channel"
    private var authorizer: MockAPIKeyAuthorizer?
    private var localWebSocketServer: MockWebSocketServer?

    override func setUp() async throws {
        localWebSocketServer = MockWebSocketServer()
        authorizer = MockAPIKeyAuthorizer(apiKey: "testApiKey")
    }

    override func tearDown() async throws {
        localWebSocketServer?.stop()
    }
    
    // MARK: - Single Event Publish
    
    func testSingleEventPublishSuccessful() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        MockWebSocketServer.messageHandler = { message in
            guard let data = message,
                  let publishObj = try? JSONDecoder().decode(PublishMessage.self, from: data),
                  publishObj.type == "publish" else {
                return Data()
            }
            
            var successful: [SuccessfulEvent] = []
            for i in 0 ..< publishObj.events.count {
                successful.append(.init(identifier: "identifier-\(i)", index: i))
            }

            let result = PublishSuccess(
                    type: "publish_success",
                    id: publishObj.id,
                    successful: successful,
                    failed: []
                )
            
            guard let encodedjsonData = try? JSONEncoder().encode(result) else {
                return Data()
            }
            
            return encodedjsonData
        }
        
        // start the server
        let endpoint = try localWebSocketServer.start()
        let events = MockEvents(
            endpointURL: endpoint,
            urlSessionBehavior: MockURLSessionBehavior(type: .success))
        let webSocketClient = events.createWebSocketClient(
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer,
            options: .default)
        
        
        let channel = "/default/channel"
        let publishSuccessExpectation = expectation(description: "Publish was successful")
        do {
            let result = try await webSocketClient.publish(
                channelName: channel,
                event: "123",
                authorizer: authorizer)
            XCTAssertEqual(result.status, .success)
            XCTAssertEqual(result.successfulEvents.count, 1)
            XCTAssertEqual(result.failedEvents.count, 0)
            publishSuccessExpectation.fulfill()
        } catch {
            XCTFail("Publish should be successful")
        }
        await fulfillment(of: [publishSuccessExpectation], timeout: 5)
    }
    
    func testSingleEventPublishSuccessWithFailedEvent() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
       MockWebSocketServer.messageHandler = { message in
            guard let data = message,
                  let publishObj = try? JSONDecoder().decode(PublishMessage.self, from: data),
                  publishObj.type == "publish" else {
                return Data()
            }
            
            var failed: [FailedEvent] = []
            for i in 0 ..< publishObj.events.count {
                failed.append(FailedEvent(
                    identifier: "identifier-\(i)",
                    index: i,
                    errorCode: nil,
                    errorMessage: nil)
                )
            }

            let result = PublishSuccess(
                type: "publish_success",
                id: publishObj.id,
                successful: [],
                failed: failed
            )
            
            guard let encodedjsonData = try? JSONEncoder().encode(result) else {
                return Data()
            }
            
            return encodedjsonData
        }
        
        // start the server
        let endpoint = try localWebSocketServer.start()
        let events = MockEvents(
            endpointURL: endpoint,
            urlSessionBehavior: MockURLSessionBehavior(type: .success))
        let webSocketClient = events.createWebSocketClient(
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer,
            options: .default)
        
        
        let publishSuccessExpectation = expectation(description: "Publish was successful")
        do {
            let result = try await webSocketClient.publish(
                channelName: channelName,
                event: "123",
                authorizer: authorizer)
            XCTAssertEqual(result.status, .failure)
            XCTAssertEqual(result.successfulEvents.count, 0)
            XCTAssertEqual(result.failedEvents.count, 1)
            publishSuccessExpectation.fulfill()
        } catch {
            XCTFail("Publish should be successful")
        }
        await fulfillment(of: [publishSuccessExpectation], timeout: 5)
    }
    
    func testSingleEventPublishError() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        MockWebSocketServer.messageHandler = { message in
            guard let data = message,
                  let publishObj = try? JSONDecoder().decode(PublishMessage.self, from: data),
                  publishObj.type == "publish" else {
                return Data()
            }

            let result = PublishError(
                type: "publish_error",
                id: publishObj.id,
                errors: [.init(
                    errorType: "UnknownError",
                    message: "unknown error message"
                )])
            
            guard let encodedjsonData = try? JSONEncoder().encode(result) else {
                return Data()
            }
            
            return encodedjsonData
        }
        
        // start the server
        let endpoint = try localWebSocketServer.start()
        let events = MockEvents(
            endpointURL: endpoint,
            urlSessionBehavior: MockURLSessionBehavior(type: .success))
        let webSocketClient = events.createWebSocketClient(
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer,
            options: .default)
        
        
        let publishErrorExpectation = expectation(description: "Publish was not successful")
        do {
            _ = try await webSocketClient.publish(
                channelName: channelName,
                event: "123",
                authorizer: authorizer)
            XCTFail("Publish should not be successful")
        } catch {
            XCTAssertNotNil(error)
            guard let error = error as? EventsError,
                case EventsError.service(_, _, _, _) = error else {
                XCTFail("Error should be of type EventError.service()")
                return
            }
            publishErrorExpectation.fulfill()
        }
        await fulfillment(of: [publishErrorExpectation], timeout: 5)
    }
    
    // MARK: - Multiple events publish
    
    func testMultipleEventPublishSuccessful() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        MockWebSocketServer.messageHandler = { message in
            guard let data = message,
                  let publishObj = try? JSONDecoder().decode(PublishMessage.self, from: data),
                  publishObj.type == "publish" else {
                return Data()
            }
            
            var successful: [SuccessfulEvent] = []
            for i in 0 ..< publishObj.events.count {
                successful.append(.init(identifier: "identifier-\(i)", index: i))
            }

            let result = PublishSuccess(
                    type: "publish_success",
                    id: publishObj.id,
                    successful: successful,
                    failed: []
                )
            
            guard let encodedjsonData = try? JSONEncoder().encode(result) else {
                return Data()
            }
            
            return encodedjsonData
        }
        
        // start the server
        let endpoint = try localWebSocketServer.start()
        let events = MockEvents(
            endpointURL: endpoint,
            urlSessionBehavior: MockURLSessionBehavior(type: .success))
        let webSocketClient = events.createWebSocketClient(
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer,
            options: .default)
        
        // publish event
        let publishSuccessExpectation = expectation(description: "Publish was successful")
        do {
            let result = try await webSocketClient.publish(
                channelName: channelName,
                events: [
                    "123",
                    "abc",
                    24,
                    1.0,
                    """
                    { \"123\" : \"abc\" }
                    """
                ],
                authorizer: authorizer)
            XCTAssertEqual(result.status, .success)
            XCTAssertEqual(result.successfulEvents.count, 5)
            XCTAssertEqual(result.failedEvents.count, 0)
            publishSuccessExpectation.fulfill()
        } catch {
            XCTFail("Publish should be successful")
        }

        await fulfillment(of: [publishSuccessExpectation], timeout: 5)
    }
    
    func testMultipleEventPublishSuccessWithFailedEvent() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        MockWebSocketServer.messageHandler = { message in
            guard let data = message,
                  let publishObj = try? JSONDecoder().decode(PublishMessage.self, from: data),
                  publishObj.type == "publish" else {
                return Data()
            }
            
            var failed: [FailedEvent] = []
            for i in 0 ..< publishObj.events.count {
                failed.append(.init(identifier: "identifier-\(i)", index: i, errorCode: nil, errorMessage: nil))
            }

            let result = PublishSuccess(
                    type: "publish_success",
                    id: publishObj.id,
                    successful: [],
                    failed: failed
                )
            
            guard let encodedjsonData = try? JSONEncoder().encode(result) else {
                return Data()
            }
            
            return encodedjsonData
        }
        
        // start the server
        let endpoint = try localWebSocketServer.start()
        let events = MockEvents(
            endpointURL: endpoint,
            urlSessionBehavior: MockURLSessionBehavior(type: .success))
        let webSocketClient = events.createWebSocketClient(
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer,
            options: .default)
        
        // publish event
        let publishSuccessExpectation = expectation(description: "Publish was successful")
        do {
            let result = try await webSocketClient.publish(
                channelName: channelName,
                events: [
                    "123",
                    "abc",
                    24,
                    1.0,
                    """
                    { \"123\" : \"abc\" }
                    """
                ],
                authorizer: authorizer)
            XCTAssertEqual(result.status, .failure)
            XCTAssertEqual(result.successfulEvents.count, 0)
            XCTAssertEqual(result.failedEvents.count, 5)
            publishSuccessExpectation.fulfill()
        } catch {
            XCTFail("Publish should be successful")
        }

        await fulfillment(of: [publishSuccessExpectation], timeout: 5)
    }
    
    func testMultipleEventPublishError() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        MockWebSocketServer.messageHandler = { message in
            guard let data = message,
                  let publishObj = try? JSONDecoder().decode(PublishMessage.self, from: data),
                  publishObj.type == "publish" else {
                return Data()
            }
            
            let result = PublishError(
                type: "publish_error",
                id: publishObj.id,
                errors: [.init(
                    errorType: "unknown error type",
                    message: "unknown error message"
                )])
            
            guard let encodedjsonData = try? JSONEncoder().encode(result) else {
                return Data()
            }
            
            return encodedjsonData
        }
        
        // start the server
        let endpoint = try localWebSocketServer.start()
        let events = MockEvents(
            endpointURL: endpoint,
            urlSessionBehavior: MockURLSessionBehavior(type: .success))
        let webSocketClient = events.createWebSocketClient(
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer,
            options: .default)
        
        // publish event
        let publishErrorExpectation = expectation(description: "Publish was not successful")
        do {
            _ = try await webSocketClient.publish(
                channelName: channelName,
                events: [
                    "123",
                    "abc",
                    24,
                    1.0,
                    """
                    { \"123\" : \"abc\" }
                    """
                ],
                authorizer: authorizer)
            XCTFail("Publish should not be successful")
        } catch {
            XCTAssertNotNil(error)
            guard let error = error as? EventsError,
                case EventsError.service(_, _, _, _) = error else {
                XCTFail("Error should be of type EventError.service()")
                return
            }
            publishErrorExpectation.fulfill()
        }
        await fulfillment(of: [publishErrorExpectation], timeout: 5)
    }
    
    // MARK: - Subscribe
    
    func testSubscribeSuccessful() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        MockWebSocketServer.messageHandler = { message in
            guard let data = message,
                  let subscribeObj = try? JSONDecoder().decode(SubscribeMessage.self, from: data),
                  subscribeObj.type == "subscribe" else {
                return Data()
            }
    
            let result = SubscribeSuccess(
                type: "subscribe_success",
                id: subscribeObj.id)
            
            guard let encodedjsonData = try? JSONEncoder().encode(result) else {
                return Data()
            }
            
            return encodedjsonData
        }
        
        // start the server
        let endpoint = try localWebSocketServer.start()
        let events = MockEvents(
            endpointURL: endpoint,
            urlSessionBehavior: MockURLSessionBehavior(type: .success))
        let webSocketClient = events.createWebSocketClient(
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer,
            options: .default)
        
        // subscribe event
        let subscribeSuccessExpectation = expectation(description: "Subscribe was successful")
        do {
            let _ = try webSocketClient.subscribe(channelName: channelName, authorizer: authorizer)
            subscribeSuccessExpectation.fulfill()
        } catch {
            XCTFail("Subscribe should be successful")
        }
        await fulfillment(of: [subscribeSuccessExpectation], timeout: 5)
    }
    
    func testSubscribeError() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        MockWebSocketServer.messageHandler = { message in
            guard let data = message,
                  let subscribeObj = try? JSONDecoder().decode(SubscribeMessage.self, from: data),
                  subscribeObj.type == "subscribe" else {
                return Data()
            }
    
            let result = SubscribeError(
                type: "subscribe_error",
                id: subscribeObj.id,
                errors: [
                    .init(errorType: "SubscriptionProcessingError", message: "There was an error processing the operation")
                ])
            
            guard let encodedjsonData = try? JSONEncoder().encode(result) else {
                return Data()
            }
            
            return encodedjsonData
        }
        
        // start the server
        let endpoint = try localWebSocketServer.start()
        let events = MockEvents(
            endpointURL: endpoint,
            urlSessionBehavior: MockURLSessionBehavior(type: .success))
        let webSocketClient = events.createWebSocketClient(
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer,
            options: .default)
        
        // subscribe event
        let subscribeFailureExpectation = expectation(description: "Subscribe was not successful")
        do {
            let subscription = try webSocketClient.subscribe(channelName: channelName, authorizer: authorizer)
            for try await _ in subscription {
                XCTFail("Subscribe should not be successful")
            }
        } catch {
            XCTAssertNotNil(error)
            guard let error = error as? EventsError,
                case EventsError.service(_, _, _, _) = error else {
                XCTFail("Error should be of type EventError.service()")
                return
            }
            subscribeFailureExpectation.fulfill()
        }
        await fulfillment(of: [subscribeFailureExpectation], timeout: 5)
    }
    
    // MARK: - Unsubscribe
    
    func testSubscriptionFinishWithUnsubscribeSuccessful() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        MockWebSocketServer.messageHandler = { message in
            guard let data = message,
                  let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let type = response["type"] as? String else {
                return Data()
            }

            var result: AppSyncWebSocketEventMessage?
            switch type {
            case "subscribe":
                result = SubscribeSuccess(
                    type: "subscribe_success",
                    id: response["id"] as! String)
            case "unsubscribe":
                result = UnsubscribeSuccess(
                    type: "unsubscribe_success",
                    id: response["id"] as! String)
            default:
                break
            }
            
            
            guard let result = result,
                  let encodedjsonData = try? JSONEncoder().encode(result) else {
                return Data()
            }
            
            return encodedjsonData
        }
        
        // start the server
        let endpoint = try localWebSocketServer.start()
        let events = MockEvents(
            endpointURL: endpoint,
            urlSessionBehavior: MockURLSessionBehavior(type: .success))
        let webSocketClient = events.createWebSocketClient(
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer,
            options: .default)
        
        // subscribe event
        let subscriptionFinishExpectation = expectation(description: "Subscription cancellation was successful")
        let task = Task {
            do {
                let subscription = try webSocketClient.subscribe(channelName: channelName, authorizer: authorizer)
                for try await _ in subscription {
                    // do nothing
                }
                subscriptionFinishExpectation.fulfill()
            } catch {
                XCTFail("Subscription cancellation should be successful")
            }
        }
        
        // wait before canceling
        try await Task.sleep(nanoseconds: UInt64(1e9))
        task.cancel()
        
        await fulfillment(of: [subscriptionFinishExpectation], timeout: 5)
    }
    
    func testSubscriptionFinishWithUnsubscribeFailure() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        MockWebSocketServer.messageHandler = { message in
            guard let data = message,
                  let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let type = response["type"] as? String else {
                return Data()
            }

            var result: AppSyncWebSocketEventMessage?
            switch type {
            case "subscribe":
                result = SubscribeSuccess(
                    type: "subscribe_success",
                    id: response["id"] as! String)
            case "unsubscribe":
                result = UnsubscribeError(
                    type: "unsubscribe_error",
                    id: response["id"] as! String,
                    errors: [
                        .init(
                            errorType: "UnknownOperationError",
                            message: "Unknown operation id \(response["id"] as! String))")
                    ])
            default:
                break
            }
            
            guard let result = result,
                  let encodedjsonData = try? JSONEncoder().encode(result) else {
                return Data()
            }
            
            return encodedjsonData
        }
        
        // start the server
        let endpoint = try localWebSocketServer.start()
        let events = MockEvents(
            endpointURL: endpoint,
            urlSessionBehavior: MockURLSessionBehavior(type: .success))
        let webSocketClient = events.createWebSocketClient(
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer,
            options: .default)
        
        // subscribe event
        let subscriptionFinishExpectation = expectation(description: "Subscription cancellation was successful")
        let task = Task {
            do {
                let subscription = try webSocketClient.subscribe(channelName: channelName, authorizer: authorizer)
                for try await _ in subscription {
                    // do nothing
                }
                subscriptionFinishExpectation.fulfill()
            } catch {
                XCTFail("Subscription cancellation should be successful")
            }
        }
        
        // wait before canceling
        try await Task.sleep(nanoseconds: UInt64(1e9))
        task.cancel()
        
        await fulfillment(of: [subscriptionFinishExpectation], timeout: 5)
    }
    
    // MARK: - Disconnect
    
    func testDisconnectSuccessfulFlushEventsTrue() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        MockWebSocketServer.messageHandler = { message in
            guard let data = message,
                  let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let type = response["type"] as? String else {
                return Data()
            }

            var result: AppSyncWebSocketEventMessage?
            switch type {
            case "subscribe":
                result = SubscribeSuccess(
                    type: "subscribe_success",
                    id: response["id"] as! String)
            case "unsubscribe":
                result = UnsubscribeSuccess(
                    type: "unsubscribe_success",
                    id: response["id"] as! String)
            default:
                break
            }
            
            guard let result = result,
                  let encodedjsonData = try? JSONEncoder().encode(result) else {
                return Data()
            }
            
            return encodedjsonData
        }
        
        // start the server
        let endpoint = try localWebSocketServer.start()
        let events = MockEvents(
            endpointURL: endpoint,
            urlSessionBehavior: MockURLSessionBehavior(type: .success))
        let webSocketClient = events.createWebSocketClient(
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer,
            options: .default)
        
        // subscribe event
        let subscriptionErrorExpectation = expectation(description: "Disconnect will cancel subscription")
        let _ = Task {
            do {
                let subscription = try webSocketClient.subscribe(channelName: channelName, authorizer: authorizer)
                for try await _ in subscription {
                    // do nothing
                }
            } catch {
                guard let error = error as? EventsError,
                      case EventsError.network(_, _, _) = error else {
                    XCTFail("Should be of EventsError.network type")
                    return
                }
                subscriptionErrorExpectation.fulfill()
            }
        }
        
        // wait before canceling
        
        try await Task.sleep(nanoseconds: UInt64(1e9))
        try await webSocketClient.disconnect(flushEvents: true)
        
        await fulfillment(of: [subscriptionErrorExpectation], timeout: 5)
    }
    
    func testDisconnectSuccessfulFlushEventFalse() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        MockWebSocketServer.messageHandler = { message in
            guard let data = message,
                  let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let type = response["type"] as? String else {
                return Data()
            }

            var result: AppSyncWebSocketEventMessage?
            switch type {
            case "subscribe":
                result = SubscribeSuccess(
                    type: "subscribe_success",
                    id: response["id"] as! String)
            case "unsubscribe":
                result = UnsubscribeSuccess(
                    type: "unsubscribe_success",
                    id: response["id"] as! String)
            default:
                break
            }
            
            guard let result = result,
                  let encodedjsonData = try? JSONEncoder().encode(result) else {
                return Data()
            }
            
            return encodedjsonData
        }
        
        // start the server
        let endpoint = try localWebSocketServer.start()
        let events = MockEvents(
            endpointURL: endpoint,
            urlSessionBehavior: MockURLSessionBehavior(type: .success))
        let webSocketClient = events.createWebSocketClient(
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer,
            options: .default)
        
        // subscribe event
        let subscriptionErrorExpectation = expectation(description: "Disconnect will cancel subscription")
        let _ = Task {
            do {
                let subscription = try webSocketClient.subscribe(channelName: channelName, authorizer: authorizer)
                for try await _ in subscription {
                    // do nothing
                }
            } catch {
                guard let error = error as? EventsError,
                      case EventsError.network(_, _, _) = error else {
                    XCTFail("Should be of EventsError.network type")
                    return
                }
                subscriptionErrorExpectation.fulfill()
            }
        }
        
        // wait before canceling
        try await Task.sleep(nanoseconds: UInt64(1e9))
        try await webSocketClient.disconnect(flushEvents: false)
        
        await fulfillment(of: [subscriptionErrorExpectation], timeout: 5)
    }
    
    func testDisconnectFailureWhenNotConnected() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        MockWebSocketServer.messageHandler = { message in
            guard let data = message,
                  let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let type = response["type"] as? String else {
                return Data()
            }

            var result: AppSyncWebSocketEventMessage?
            switch type {
            case "subscribe":
                result = SubscribeSuccess(
                    type: "subscribe_success",
                    id: response["id"] as! String)
            case "unsubscribe":
                result = UnsubscribeSuccess(
                    type: "unsubscribe_success",
                    id: response["id"] as! String)
            default:
                break
            }
            
            guard let result = result,
                  let encodedjsonData = try? JSONEncoder().encode(result) else {
                return Data()
            }
            
            return encodedjsonData
        }
        
        // start the server
        let endpoint = try localWebSocketServer.start()
        let events = MockEvents(
            endpointURL: endpoint,
            urlSessionBehavior: MockURLSessionBehavior(type: .success))
        let webSocketClient = events.createWebSocketClient(
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer,
            options: .default)
        
        // disconnect without calling any publish/subscribe API
        let disconnectFailureExpectation = expectation(description: "Disconnect should fail")
        let _ = Task {
            do {
                try await webSocketClient.disconnect(flushEvents: true)
            } catch {
                guard let error = error as? EventsError,
                      case EventsError.unknown(_, _) = error else {
                    XCTFail("Should be of EventsError.unknown type")
                    return
                }
                disconnectFailureExpectation.fulfill()
            }
        }
        
        await fulfillment(of: [disconnectFailureExpectation], timeout: 5)
    }
    
    func testSubscriptionDisconnectOnNetworkError() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        MockWebSocketServer.messageHandler = { message in
            guard let data = message,
                  let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let type = response["type"] as? String else {
                return Data()
            }

            var result: AppSyncWebSocketEventMessage?
            switch type {
            case "subscribe":
                result = SubscribeSuccess(
                    type: "subscribe_success",
                    id: response["id"] as! String)
            case "unsubscribe":
                result = UnsubscribeSuccess(
                    type: "unsubscribe_success",
                    id: response["id"] as! String)
            default:
                break
            }
            
            guard let result = result,
                  let encodedjsonData = try? JSONEncoder().encode(result) else {
                return Data()
            }
            
            return encodedjsonData
        }
        
        // start the server
        let endpoint = try localWebSocketServer.start()
        let events = MockEvents(
            endpointURL: endpoint,
            urlSessionBehavior: MockURLSessionBehavior(type: .success))
        let webSocketClient = events.createWebSocketClient(
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer,
            options: .default)
        
        // subscribe event
        let subscriptionErrorExpectation = expectation(description: "Transient network error will cancel subscription")
        let _ = Task {
            do {
                let subscription = try webSocketClient.subscribe(channelName: channelName, authorizer: authorizer)
                for try await _ in subscription {
                    // do nothing
                }
            } catch {
                guard let error = error as? EventsError,
                      case EventsError.network(_, _, _) = error else {
                    XCTFail("Should be of EventsError.network type")
                    return
                }
                subscriptionErrorExpectation.fulfill()
            }
        }
        
        // wait before canceling
        try await Task.sleep(nanoseconds: UInt64(1e9))
        localWebSocketServer.sendTransientFailureToConnections(closeCode: .internalServerError)
        
        await fulfillment(of: [subscriptionErrorExpectation], timeout: 5)
    }
}
