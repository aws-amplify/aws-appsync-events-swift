//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSAppSyncEvents
import Combine
import XCTest

class AppSyncWebSocketClientTests: XCTestCase {

    private var localWebSocketServer: MockWebSocketServer?
    private var authorizer: MockAPIKeyAuthorizer?
    private var cancellables = Set<AnyCancellable>()

    override func setUp() async throws {
        localWebSocketServer = MockWebSocketServer()
        authorizer = MockAPIKeyAuthorizer(apiKey: "testApiKey")
    }

    override func tearDown() async throws {
        localWebSocketServer?.stop()
    }
    
    // MARK: - Connect

    func testConnectWithHTTPSchemeSuccessful() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        let endpoint = try localWebSocketServer.start()
        let webSocketClient = AppSyncWebSocketClient(
            endpointURL: endpoint,
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer)
        try await verifyConnected(webSocketClient)
    }
    
    // MARK: - Simulate server error
    
    func testServerErrorAfterSuccessfulConnection() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        let endpoint = try localWebSocketServer.start()
        let webSocketClient = AppSyncWebSocketClient(
            endpointURL: endpoint,
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer)
        try await verifyConnected(webSocketClient)
        
        let connectionClosureExpectation = expectation(description: "Connection should be closed")
        webSocketClient.publisher.sink { event in
            switch event {
            case .disconnected(let closeCode, _):
                XCTAssertEqual(closeCode, URLSessionWebSocketTask.CloseCode.internalServerError)
                connectionClosureExpectation.fulfill()
            default:
                break
            }
        }.store(in: &cancellables)
        
        // simulate server disconnect
        localWebSocketServer.sendTransientFailureToConnections(closeCode: .internalServerError)
        await fulfillment(of: [connectionClosureExpectation], timeout: 5)
    }
    
    // MARK: - Single Event Publish
    
    func testSingleEventPublishSuccessful() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        let id = UUID().uuidString
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
        
        // wait for connection to establish
        let endpoint = try localWebSocketServer.start()
        let webSocketClient = AppSyncWebSocketClient(
            endpointURL: endpoint,
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer)
        try await verifyConnected(webSocketClient)
        
        
        let channel = "/default/channel"
        let publishSuccessExpectation = expectation(description: "Publish was successful")
        webSocketClient.publisher.sink { event in
            switch event {
            case .string(let string):
                guard let data = string.data(using: .utf8),
                      let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let type = response["type"] as? String else {
                    break
                }
                
                switch type {
                case "publish_success":
                    if let message = try? JSONDecoder().decode(PublishSuccess.self, from: data) {
                        XCTAssertEqual(message.id, id)
                        XCTAssertEqual(message.successful?.count, 1)
                        XCTAssertEqual(message.failed?.count, 0)
                        publishSuccessExpectation.fulfill()
                    }
                default:
                    break
                }
            default:
                break
            }
        }.store(in: &cancellables)
        
        // publish event
        try await webSocketClient.publish(
            id: id,
            channel: channel,
            event: "123")
        await fulfillment(of: [publishSuccessExpectation], timeout: 5)
    }
    
    func testSingleEventPublishSuccessWithFailedEvent() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        let id = UUID().uuidString
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
        
        // wait for connection to establish
        let endpoint = try localWebSocketServer.start()
        let webSocketClient = AppSyncWebSocketClient(
            endpointURL: endpoint,
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer)
        try await verifyConnected(webSocketClient)
        
        
        let channel = "/default/channel"
        let publishSuccessExpectation = expectation(description: "Publish was successful")
        webSocketClient.publisher.sink { event in
            switch event {
            case .string(let string):
                guard let data = string.data(using: .utf8),
                      let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let type = response["type"] as? String else {
                    break
                }
                
                switch type {
                case "publish_success":
                    if let message = try? JSONDecoder().decode(PublishSuccess.self, from: data) {
                        XCTAssertEqual(message.id, id)
                        XCTAssertEqual(message.successful?.count, 0)
                        XCTAssertEqual(message.failed?.count, 1)
                        publishSuccessExpectation.fulfill()
                    }
                default:
                    break
                }
            default:
                break
            }
        }.store(in: &cancellables)
        
        // publish event
        try await webSocketClient.publish(
            id: id,
            channel: channel,
            event: "123")
        await fulfillment(of: [publishSuccessExpectation], timeout: 5)
    }
    
    func testSingleEventPublishError() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        let id = UUID().uuidString
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
        
        // wait for connection to establish
        let endpoint = try localWebSocketServer.start()
        let webSocketClient = AppSyncWebSocketClient(
            endpointURL: endpoint,
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer)
        try await verifyConnected(webSocketClient)
        
        
        let channel = "/default/channel"
        let publishErrorExpectation = expectation(description: "Publish was successful")
        webSocketClient.publisher.sink { event in
            switch event {
            case .string(let string):
                guard let data = string.data(using: .utf8),
                      let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let type = response["type"] as? String else {
                    break
                }
                
                switch type {
                case "publish_error":
                    if let message = try? JSONDecoder().decode(PublishError.self, from: data) {
                        XCTAssertEqual(message.id, id)
                        XCTAssertTrue(message.errors != nil && message.errors!.count > 0)
                        publishErrorExpectation.fulfill()
                    }
                default:
                    break
                }
            default:
                break
            }
        }.store(in: &cancellables)
        
        // publish event
        try await webSocketClient.publish(
            id: id,
            channel: channel,
            event: "123")
        await fulfillment(of: [publishErrorExpectation], timeout: 5)
    }
    
    // MARK: - Multiple events publish
    
    func testMultipleEventPublishSuccessful() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        let id = UUID().uuidString
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
        
        // wait for connection to establish
        let endpoint = try localWebSocketServer.start()
        let webSocketClient = AppSyncWebSocketClient(
            endpointURL: endpoint,
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer)
        try await verifyConnected(webSocketClient)
        
        
        let channel = "/default/channel"
        let publishSuccessExpectation = expectation(description: "Publish was successful")
        webSocketClient.publisher.sink { event in
            switch event {
            case .string(let string):
                guard let data = string.data(using: .utf8),
                      let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let type = response["type"] as? String else {
                    break
                }
                
                switch type {
                case "publish_success":
                    if let message = try? JSONDecoder().decode(PublishSuccess.self, from: data) {
                        XCTAssertEqual(message.id, id)
                        XCTAssertEqual(message.successful?.count, 5)
                        XCTAssertEqual(message.failed?.count, 0)
                        publishSuccessExpectation.fulfill()
                    }
                default:
                    break
                }
            default:
                break
            }
        }.store(in: &cancellables)
        
        // publish event
        try await webSocketClient.publish(
            id: id,
            channel: channel,
            events: [
                "123",
                "abc",
                24,
                1.0, 
                """
                { \"123\" : \"abc\" }
                """
            ])
        await fulfillment(of: [publishSuccessExpectation], timeout: 5)
    }
    
    func testMultipleEventPublishError() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        let id = UUID().uuidString
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
        
        // wait for connection to establish
        let endpoint = try localWebSocketServer.start()
        let webSocketClient = AppSyncWebSocketClient(
            endpointURL: endpoint,
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer)
        try await verifyConnected(webSocketClient)
        
        
        let channel = "/default/channel"
        let publishErrorExpectation = expectation(description: "Publish was successful")
        webSocketClient.publisher.sink { event in
            switch event {
            case .string(let string):
                guard let data = string.data(using: .utf8),
                      let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let type = response["type"] as? String else {
                    break
                }
                
                switch type {
                case "publish_error":
                    if let message = try? JSONDecoder().decode(PublishError.self, from: data) {
                        XCTAssertEqual(message.id, id)
                        XCTAssertTrue(message.errors != nil && message.errors!.count > 0)
                        publishErrorExpectation.fulfill()
                    }
                default:
                    break
                }
            default:
                break
            }
        }.store(in: &cancellables)
        
        // publish event
        try await webSocketClient.publish(
            id: id,
            channel: channel,
            events: [
                "123",
                "abc",
                24,
                1.0,
                """
                { \"123\" : \"abc\" }
                """
            ])
        await fulfillment(of: [publishErrorExpectation], timeout: 5)
    }
    
    func testMultipleEventPublishWithFailedEvent() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        let id = UUID().uuidString
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
        
        // wait for connection to establish
        let endpoint = try localWebSocketServer.start()
        let webSocketClient = AppSyncWebSocketClient(
            endpointURL: endpoint,
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer)
        try await verifyConnected(webSocketClient)
        
        
        let channel = "/default/channel"
        let publishSuccessExpectation = expectation(description: "Publish was successful")
        webSocketClient.publisher.sink { event in
            switch event {
            case .string(let string):
                guard let data = string.data(using: .utf8),
                      let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let type = response["type"] as? String else {
                    break
                }
                
                switch type {
                case "publish_success":
                    if let message = try? JSONDecoder().decode(PublishSuccess.self, from: data) {
                        XCTAssertEqual(message.id, id)
                        XCTAssertEqual(message.successful?.count, 0)
                        XCTAssertEqual(message.failed?.count, 5)
                        publishSuccessExpectation.fulfill()
                    }
                default:
                    break
                }
            default:
                break
            }
        }.store(in: &cancellables)
        
        // publish event
        try await webSocketClient.publish(
            id: id,
            channel: channel,
            events: [
                "123",
                "abc",
                24,
                1.0,
                """
                { \"123\" : \"abc\" }
                """
            ])
        await fulfillment(of: [publishSuccessExpectation], timeout: 5)
    }

    // MARK: - Disconnect
    
    func testDisconnectSuccessfulFlushEventsTrue() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        let endpoint = try localWebSocketServer.start()
        let disconnectedExpectation = expectation(description: "WebSocket did disconnect")

        let webSocketClient = AppSyncWebSocketClient(
            endpointURL: endpoint,
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer)
        
        try await verifyConnected(webSocketClient)

        webSocketClient.publisher
            .sink { event in
                switch event {
                case let .disconnected(closeCode, reason):
                    XCTAssertNotNil(reason)
                    XCTAssertEqual(closeCode, .normalClosure)
                    disconnectedExpectation.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        try await webSocketClient.disconnect(flushEvents: true)
        await fulfillment(of: [disconnectedExpectation], timeout: 5)
    }
    
    func testDisconnectSuccessfulFlushEventFalse() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        let endpoint = try localWebSocketServer.start()
        let disconnectedExpectation = expectation(description: "WebSocket did disconnect")

        let webSocketClient = AppSyncWebSocketClient(
            endpointURL: endpoint,
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer)
        
        try await verifyConnected(webSocketClient)

        webSocketClient.publisher
            .sink { event in
                switch event {
                case let .disconnected(closeCode, reason):
                    XCTAssertNotNil(reason)
                    XCTAssertEqual(closeCode, .goingAway)
                    disconnectedExpectation.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        try await webSocketClient.disconnect(flushEvents: false)
        await fulfillment(of: [disconnectedExpectation], timeout: 5)
    }
    
    func testDisconnectFailureWhenNotConnected() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        let endpoint = try localWebSocketServer.start()
        let disconnectFailureExpectation = expectation(description: "WebSocket disconnect failure")

        let webSocketClient = AppSyncWebSocketClient(
            endpointURL: endpoint,
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer)
        
        do {
            try await webSocketClient.disconnect()
        } catch {
            XCTAssertNotNil(error)
            guard case EventsError.unknown(_, _) = error else {
                XCTFail("Error type should be EventsError.unknown")
                return
            }
            disconnectFailureExpectation.fulfill()
        }
        
        await fulfillment(of: [disconnectFailureExpectation], timeout: 5)
    }
    
    // MARK: - Subscribe
    
    func testSubscribeSuccessful() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        let id = UUID().uuidString
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
        
        // wait for connection to establish
        let endpoint = try localWebSocketServer.start()
        let webSocketClient = AppSyncWebSocketClient(
            endpointURL: endpoint,
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer)
        try await verifyConnected(webSocketClient)
        
        
        let channel = "/default/channel"
        let subscribeSuccessExpectation = expectation(description: "Subscribe was successful")
        webSocketClient.publisher.sink { event in
            switch event {
            case .string(let string):
                guard let data = string.data(using: .utf8),
                      let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let type = response["type"] as? String else {
                    break
                }
                
                switch type {
                case "subscribe_success":
                    if let message = try? JSONDecoder().decode(SubscribeSuccess.self, from: data) {
                        XCTAssertEqual(message.id, id)
                        subscribeSuccessExpectation.fulfill()
                    }
                default:
                    break
                }
            default:
                break
            }
        }.store(in: &cancellables)
        
        // publish event
        try await webSocketClient.subscribe(id: id, channel: channel)
        await fulfillment(of: [subscribeSuccessExpectation], timeout: 5)
    }
    
    
    func testSubscribeError() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        let id = UUID().uuidString
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
        
        // wait for connection to establish
        let endpoint = try localWebSocketServer.start()
        let webSocketClient = AppSyncWebSocketClient(
            endpointURL: endpoint,
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer)
        try await verifyConnected(webSocketClient)
        
        
        let channel = "/default/channel"
        let subscribeErrorExpectation = expectation(description: "Subscribe was not successful")
        webSocketClient.publisher.sink { event in
            switch event {
            case .string(let string):
                guard let data = string.data(using: .utf8),
                      let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let type = response["type"] as? String else {
                    break
                }
                
                switch type {
                case "subscribe_error":
                    if let message = try? JSONDecoder().decode(SubscribeError.self, from: data) {
                        XCTAssertEqual(message.id, id)
                        XCTAssertTrue(message.errors != nil && message.errors!.count > 0)
                        XCTAssertEqual(message.errors!.first!.errorType, "SubscriptionProcessingError")
                        subscribeErrorExpectation.fulfill()
                    }
                default:
                    break
                }
            default:
                break
            }
        }.store(in: &cancellables)
        
        // publish event
        try await webSocketClient.subscribe(id: id, channel: channel)
        await fulfillment(of: [subscribeErrorExpectation], timeout: 5)
    }
    
    // MARK: - Unsubscribe
    
    func testUnsubscribeSuccessful() async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        let id = UUID().uuidString
        MockWebSocketServer.messageHandler = { message in
            guard let data = message,
                  let subscribeObj = try? JSONDecoder().decode(UnsubscribeMessage.self, from: data),
                  subscribeObj.type == "unsubscribe" else {
                return Data()
            }
    
            let result = UnsubscribeSuccess(
                type: "unsubscribe_success",
                id: subscribeObj.id)
            
            guard let encodedjsonData = try? JSONEncoder().encode(result) else {
                return Data()
            }
            
            return encodedjsonData
        }
        
        // wait for connection to establish
        let endpoint = try localWebSocketServer.start()
        let webSocketClient = AppSyncWebSocketClient(
            endpointURL: endpoint,
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer)
        try await verifyConnected(webSocketClient)
        
        
        let unsubscribeSuccessExpectation = expectation(description: "Unsubscribe was successful")
        webSocketClient.publisher.sink { event in
            switch event {
            case .string(let string):
                guard let data = string.data(using: .utf8),
                      let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let type = response["type"] as? String else {
                    break
                }
                
                switch type {
                case "unsubscribe_success":
                    if let message = try? JSONDecoder().decode(UnsubscribeSuccess.self, from: data) {
                        XCTAssertEqual(message.id, id)
                        unsubscribeSuccessExpectation.fulfill()
                    }
                default:
                    break
                }
            default:
                break
            }
        }.store(in: &cancellables)
        
        // publish event
        try await webSocketClient.unsubscribe(id: id)
        await fulfillment(of: [unsubscribeSuccessExpectation], timeout: 5)
    }
    
    func testUnsubscribeError()  async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        let id = UUID().uuidString
        MockWebSocketServer.messageHandler = { message in
            guard let data = message,
                  let subscribeObj = try? JSONDecoder().decode(UnsubscribeMessage.self, from: data),
                  subscribeObj.type == "unsubscribe" else {
                return Data()
            }
    
            let result = UnsubscribeError(
                type: "unsubscribe_error",
                id: subscribeObj.id,
                errors: [
                    .init(errorType: "UnknownOperationError", message: "Unknown operation id \(id)")
                ])
            
            guard let encodedjsonData = try? JSONEncoder().encode(result) else {
                return Data()
            }
            
            return encodedjsonData
        }
        
        // wait for connection to establish
        let endpoint = try localWebSocketServer.start()
        let webSocketClient = AppSyncWebSocketClient(
            endpointURL: endpoint,
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer)
        try await verifyConnected(webSocketClient)
        
        
        let unsubscribeSuccessExpectation = expectation(description: "Unsubscribe was successful")
        webSocketClient.publisher.sink { event in
            switch event {
            case .string(let string):
                guard let data = string.data(using: .utf8),
                      let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let type = response["type"] as? String else {
                    break
                }
                
                switch type {
                case "unsubscribe_error":
                    if let message = try? JSONDecoder().decode(UnsubscribeError.self, from: data) {
                        XCTAssertEqual(message.id, id)
                        unsubscribeSuccessExpectation.fulfill()
                    }
                default:
                    break
                }
            default:
                break
            }
        }.store(in: &cancellables)
        
        // publish event
        try await webSocketClient.unsubscribe(id: id)
        await fulfillment(of: [unsubscribeSuccessExpectation], timeout: 5)
    }
    
    // MARK: - Data Event
    
    func testDataReceived()  async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        MockWebSocketServer.messageHandler = { data in
            return data
        }
        
        let id = UUID().uuidString
        let stringToSend: String = "123"
        
        // wait for connection to establish
        let endpoint = try localWebSocketServer.start()
        let webSocketClient = AppSyncWebSocketClient(
            endpointURL: endpoint,
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer)
        try await verifyConnected(webSocketClient)
        
        
        let dataReceivedExpectation = expectation(description: "Data was successfully received")
        webSocketClient.publisher.sink { event in
            switch event {
            case .string(let string):
                guard let data = string.data(using: .utf8),
                      let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let type = response["type"] as? String else {
                    break
                }
                
                switch type {
                case "data":
                    if let message = try? JSONDecoder().decode(SubscribeData.self, from: data) {
                        XCTAssertEqual(message.id, id)
                        XCTAssertEqual(message.event, stringToSend)
                        dataReceivedExpectation.fulfill()
                    }
                default:
                    break
                }
            default:
                break
            }
        }.store(in: &cancellables)
        
        // send event through server
        let data = SubscribeData(
            type: "data",
            id: id,
            event: stringToSend)
        guard let encodedjsonData = try? JSONEncoder().encode(data),
              let jsonString = String(data: encodedjsonData, encoding: .utf8) else {
            XCTFail("Error occurred while encoding")
            return
        }
        localWebSocketServer.sendData(data: jsonString.data(using: .utf8)!)
        await fulfillment(of: [dataReceivedExpectation], timeout: 5)
    }
    
    // MARK: - Broadcast Error
    func testBroadcastErrorReceived()  async throws {
        guard let localWebSocketServer = localWebSocketServer,
              let authorizer = authorizer else {
            XCTFail("Web socket server/authorizer not set up or Invalid URL")
            return
        }
        
        let id = UUID().uuidString
        MockWebSocketServer.messageHandler = { data in
            return data
        }
        
        // wait for connection to establish
        let endpoint = try localWebSocketServer.start()
        let webSocketClient = AppSyncWebSocketClient(
            endpointURL: endpoint,
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer)
        try await verifyConnected(webSocketClient)
        
        
        let broadcastErrorReceivedExpectation = expectation(description: "Data was successfully received")
        webSocketClient.publisher.sink { event in
            switch event {
            case .string(let string):
                guard let data = string.data(using: .utf8),
                      let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let type = response["type"] as? String else {
                    break
                }
                
                switch type {
                case "broadcast_error":
                    if let message = try? JSONDecoder().decode(BroadcastError.self, from: data) {
                        XCTAssertEqual(message.id, id)
                        XCTAssertTrue(message.errors != nil && message.errors!.count > 0)
                        XCTAssertEqual(message.errors!.first!.errorType, "MessageProcessingError")
                        broadcastErrorReceivedExpectation.fulfill()
                    }
                default:
                    break
                }
            default:
                break
            }
        }.store(in: &cancellables)
        
        // send event through server
        let data = BroadcastError(
            type: "broadcast_error",
            id: id,
            errors: [
                .init(errorType: "MessageProcessingError", message: "There was an error processing the message")
            ])
        guard let encodedjsonData = try? JSONEncoder().encode(data),
              let jsonString = String(data: encodedjsonData, encoding: .utf8) else {
            XCTFail("Error occurred while encoding")
            return
        }
        localWebSocketServer.sendData(data: jsonString.data(using: .utf8)!)
        await fulfillment(of: [broadcastErrorReceivedExpectation], timeout: 5)
    }
    
    // MARK: - URLRequestInterceptor
    
    func testConnectURLRequestInterceptorCalled() async throws {
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
        
        // wait for connection to establish
        let endpoint = try localWebSocketServer.start()
        let webSocketClient = AppSyncWebSocketClient(
            endpointURL: endpoint,
            connectAuthorizer: authorizer,
            publishAuthorizer: authorizer,
            subscribeAuthorizer: authorizer,
            options: .init(interceptor: MockWebSocketURLRequestInterceptor()))
        try await verifyConnected(webSocketClient)
        
        XCTAssertTrue(webSocketClient.request.allHTTPHeaderFields?[MockWebSocketURLRequestInterceptor.mockHeaderKey] != nil)
        XCTAssertEqual(
            webSocketClient.request.allHTTPHeaderFields![MockWebSocketURLRequestInterceptor.mockHeaderKey],
            MockWebSocketURLRequestInterceptor.mockHeaderValue)
    }

    // MARK: - Private helpers
    
    private func verifyConnected(
           _ webSocketClient: AppSyncWebSocketClient,
           autoConnectOnNetworkStatusChange: Bool = false,
           autoRetryOnConnectionFailure: Bool = false
   ) async throws {
       let connectedExpectation = expectation(description: "WebSocket did connect")
       webSocketClient.publisher.sink { event in
           switch event {
           case .connected:
               connectedExpectation.fulfill()
           default:
               break
           }
       }.store(in: &cancellables)

       try await webSocketClient.connect()
       await fulfillment(of: [connectedExpectation], timeout: 5)
   }
}
