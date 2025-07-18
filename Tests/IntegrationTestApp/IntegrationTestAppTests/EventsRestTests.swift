//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Combine
import AWSAppSyncEvents

class EventsRestTests: IntegrationTestBase {
    
    override func tearDown() async throws {
        await AuthSignInHelper.signOut()
    }
    
    // MARK: - Single event publish
    
    /// - Given: An events API set up with API Key Authorization
    /// - When: A single event is published over HTTP
    /// - Then: The operation is successful
    func testSingleEventPublishSuccessAPIKey() async throws {
        guard let events = events,
              let _ = endpointURL,
              let apiKeyAuthorizer = apiKeyAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let restClient = events.createRestClient(publishAuthorizer: apiKeyAuthorizer)
        let event = JSONValue(stringLiteral: "123")
        do {
            let result = try await restClient.publish(
                channelName: defaultChannel,
                event: event,
                authorizer: apiKeyAuthorizer
            )
            guard PublishResultStatus.success == result.status else {
                XCTFail("Publish result should be success")
                return
            }
            XCTAssertEqual(result.status, .success)
            XCTAssertEqual(result.successfulEvents.count, 1)
            XCTAssertEqual(result.failedEvents.count, 0)
        } catch {
            XCTFail("Publish should succeed.")
        }
    }
    
    /// - Given: An events API set up with Cognito User Pool Authorization
    /// - When: A single event is published over HTTP
    /// - Then: The operation is successful
    func testSingleEventPublishSuccessAuthToken() async throws {
        guard let events = events,
              let _ = endpointURL,
              let authTokenAuthorizer = authTokenAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        try await signIn()
        
        let restClient = events.createRestClient(publishAuthorizer: authTokenAuthorizer)
        let event = JSONValue(stringLiteral: "123")
        do {
            let result = try await restClient.publish(
                channelName: defaultChannel,
                event: event
            )
            guard PublishResultStatus.success == result.status else {
                XCTFail("Publish result should be success")
                return
            }
            XCTAssertEqual(result.status, .success)
            XCTAssertEqual(result.successfulEvents.count, 1)
            XCTAssertEqual(result.failedEvents.count, 0)
        } catch {
            XCTFail("Publish should succeed.")
        }
    }
    
    /// - Given: An events API set up with IAM Unauthenticated Role
    /// - When: A single event is published over HTTP
    /// - Then: The operation is successful
    func testSingleEventPublishSuccessIAMUnAuth() async throws {
        guard let events = events,
              let _ = endpointURL,
              let iamAuthorizer = iamAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let restClient = events.createRestClient(publishAuthorizer: iamAuthorizer)
        let event = JSONValue(stringLiteral: "123")
        do {
            let result = try await restClient.publish(
                channelName: defaultChannel,
                event: event
            )
            guard PublishResultStatus.success == result.status else {
                XCTFail("Publish result should be success")
                return
            }
            XCTAssertEqual(result.status, .success)
            XCTAssertEqual(result.successfulEvents.count, 1)
            XCTAssertEqual(result.failedEvents.count, 0)
        } catch {
            XCTFail("Publish should succeed.")
        }
    }
    
    /// - Given: An events API set up with IAM Authenticated Role
    /// - When: A single event is published over HTTP
    /// - Then: The operation is successful
    func testSingleEventPublishSuccessIAMAuth() async throws {
        guard let events = events,
              let _ = endpointURL,
              let iamAuthorizer = iamAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        try await signIn()
        
        let restClient = events.createRestClient(publishAuthorizer: iamAuthorizer)
        let event = JSONValue(stringLiteral: "123")
        do {
            let result = try await restClient.publish(
                channelName: defaultChannel,
                event: event
            )
            guard PublishResultStatus.success == result.status else {
                XCTFail("Publish result should be success")
                return
            }
            XCTAssertEqual(result.status, .success)
            XCTAssertEqual(result.successfulEvents.count, 1)
            XCTAssertEqual(result.failedEvents.count, 0)
        } catch {
            XCTFail("Publish should succeed.")
        }
    }
    
    // MARK: - Multiple events publish
    
    /// - Given: An events API set up with API Key Authorization
    /// - When: Multiple events are published over HTTP
    /// - Then: The operation is successful
    func testMultipleEventsPublishSuccessAPIKey() async throws {
        guard let events = events,
              let _ = endpointURL,
              let apiKeyAuthorizer = apiKeyAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let restClient = events.createRestClient(publishAuthorizer: apiKeyAuthorizer)
        let eventsList = [
            JSONValue(stringLiteral: "123"),
            JSONValue(booleanLiteral: true),
            JSONValue(floatLiteral: 1.25),
            JSONValue(integerLiteral: 37),
            JSONValue(dictionaryLiteral: ("key", "value"))
        ]
        do {
            let result = try await restClient.publish(
                channelName: defaultChannel,
                events: eventsList
            )
            guard PublishResultStatus.success == result.status else {
                XCTFail("Publish result should be success")
                return
            }
            XCTAssertEqual(result.status, .success)
            XCTAssertEqual(result.successfulEvents.count, 5)
            XCTAssertEqual(result.failedEvents.count, 0)
        } catch {
            XCTFail("Publish should succeed.")
        }
    }
    
    /// - Given: An events API set up with Cognito User Pool Authorization
    /// - When: Multiple events are published over HTTP
    /// - Then: The operation is successful
    func testMultipleEventsPublishSuccessAuthToken() async throws {
        guard let events = events,
              let _ = endpointURL,
              let authTokenAuthorizer = authTokenAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        try await signIn()
        
        let restClient = events.createRestClient(publishAuthorizer: authTokenAuthorizer)
        let eventsList = [
            JSONValue(stringLiteral: "123"),
            JSONValue(booleanLiteral: true),
            JSONValue(floatLiteral: 1.25),
            JSONValue(integerLiteral: 37),
            JSONValue(dictionaryLiteral: ("key", "value"))
        ]
        do {
            let result = try await restClient.publish(
                channelName: defaultChannel,
                events: eventsList
            )
            guard PublishResultStatus.success == result.status else {
                XCTFail("Publish result should be success")
                return
            }
            XCTAssertEqual(result.status, .success)
            XCTAssertEqual(result.successfulEvents.count, 5)
            XCTAssertEqual(result.failedEvents.count, 0)
        } catch {
            XCTFail("Publish should succeed.")
        }
    }
    
    /// - Given: An events API set up with IAM Unauthenticated Role
    /// - When: Multiple events are published over HTTP
    /// - Then: The operation is successful
    func testMultipleEventsPublishSuccessIAMUnAuth() async throws {
        guard let events = events,
              let _ = endpointURL,
              let iamAuthorizer = iamAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let restClient = events.createRestClient(publishAuthorizer: iamAuthorizer)
        let eventsList = [
            JSONValue(stringLiteral: "123"),
            JSONValue(booleanLiteral: true),
            JSONValue(floatLiteral: 1.25),
            JSONValue(integerLiteral: 37),
            JSONValue(dictionaryLiteral: ("key", "value"))
        ]
        do {
            let result = try await restClient.publish(
                channelName: defaultChannel,
                events: eventsList
            )
            guard PublishResultStatus.success == result.status else {
                XCTFail("Publish result should be success")
                return
            }
            XCTAssertEqual(result.status, .success)
            XCTAssertEqual(result.successfulEvents.count, 5)
            XCTAssertEqual(result.failedEvents.count, 0)
        } catch {
            XCTFail("Publish should succeed.")
        }
    }
    
    /// - Given: An events API set up with IAM Authenticated Role
    /// - When: Multiple events are published over HTTP
    /// - Then: The operation is successful
    func testMultipleEventsPublishSuccessIAMAuth() async throws {
        guard let events = events,
              let _ = endpointURL,
              let iamAuthorizer = iamAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        try await signIn()
        
        let restClient = events.createRestClient(publishAuthorizer: iamAuthorizer)
        let eventsList = [
            JSONValue(stringLiteral: "123"),
            JSONValue(booleanLiteral: true),
            JSONValue(floatLiteral: 1.25),
            JSONValue(integerLiteral: 37),
            JSONValue(dictionaryLiteral: ("key", "value"))
        ]
        do {
            let result = try await restClient.publish(
                channelName: defaultChannel,
                events: eventsList
            )
            guard PublishResultStatus.success == result.status else {
                XCTFail("Publish result should be success")
                return
            }
            XCTAssertEqual(result.status, .success)
            XCTAssertEqual(result.successfulEvents.count, 5)
            XCTAssertEqual(result.failedEvents.count, 0)
        } catch {
            XCTFail("Publish should succeed.")
        }
    }
    
    // MARK: - Concurrent scenarios
    
    /// - Given: An events API set up with appropriate Authorization
    /// - When: Multiple events are published over HTTP from concurrent tasks (200)
    /// - Then: The operation is successful
    func testConcurrentMultipleEventsPublishSuccess() async throws {
        guard let events = events,
              let _ = endpointURL,
              let apiKeyAuthorizer = apiKeyAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let restClient = events.createRestClient(publishAuthorizer: apiKeyAuthorizer)
        let eventsList = [
            JSONValue(stringLiteral: "123"),
            JSONValue(booleanLiteral: true),
            JSONValue(floatLiteral: 1.25),
            JSONValue(integerLiteral: 37),
            JSONValue(dictionaryLiteral: ("key", "value"))
        ]
        
        var tasks = [AnyCancellable]()
        let concurrencyCount = 200
        let concurrentPublishExpectation = expectation(description: "Concurrent publish over HTTP was successful")
        concurrentPublishExpectation.expectedFulfillmentCount = concurrencyCount
        for _ in 0 ..< concurrencyCount {
            let task = Task {
                do {
                    let result = try await restClient.publish(
                        channelName: defaultChannel,
                        events: eventsList
                    )
                    guard PublishResultStatus.success == result.status else {
                        XCTFail("Publish result should be success")
                        return
                    }
                    XCTAssertEqual(result.status, .success)
                    XCTAssertEqual(result.successfulEvents.count, 5)
                    XCTAssertEqual(result.failedEvents.count, 0)
                    concurrentPublishExpectation.fulfill()
                } catch {
                    XCTFail("Publish should succeed.")
                }
            }
            tasks.append(task.toAnyCancellable)
        }
        
        await fulfillment(of: [concurrentPublishExpectation], timeout: timeoutInSeconds)
        for task in tasks {
            task.cancel()
        }
    }
    
    // MARK: - Failure scenarios
    
    /// - Given: An events API set up with appropriate authorization
    /// - When: Multiple events greater than 5 are published over HTTP
    /// - Then: The operation should fail
    func testMultipleEventsPublishLimitFailure() async throws {
        guard let events = events,
              let _ = endpointURL,
              let apiKeyAuthorizer = apiKeyAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let restClient = events.createRestClient(publishAuthorizer: apiKeyAuthorizer)
        let eventsList = [
            JSONValue(stringLiteral: "123"),
            JSONValue(booleanLiteral: true),
            JSONValue(floatLiteral: 1.25),
            JSONValue(integerLiteral: 37),
            JSONValue(dictionaryLiteral: ("key", "value")),
            JSONValue(stringLiteral: "678"),
            JSONValue(booleanLiteral: false),
            JSONValue(floatLiteral: 3.14)
        ]
        do {
            let _ = try await restClient.publish(
                channelName: defaultChannel,
                events: eventsList
            )
            XCTFail("Publish should not succeed.")
        } catch {
            XCTAssertNotNil(error)
            guard case EventsError.service(_, _, _, _) = error else {
                XCTFail("Error should be of type .service")
                return
            }
        }
    }
    
    /// - Given: An events API set up with appropriate authorization
    /// - When: Invalid JSON is published over HTTP
    /// - Then: The operation should fail
    func testInvalidJSONPublishFailure() async throws {
        guard let events = events,
              let _ = endpointURL,
              let apiKeyAuthorizer = apiKeyAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let restClient = events.createRestClient(publishAuthorizer: apiKeyAuthorizer)
        let event = JSONValue(floatLiteral: .nan)
        do {
            let _ = try await restClient.publish(
                channelName: defaultChannel,
                event: event
            )
            XCTFail("Publish should not succeed.")
        } catch {
            XCTAssertNotNil(error)
            guard case EventsError.unknown(_, _) = error else {
                XCTFail("Error should be of type .unknown")
                return
            }
        }
    }
    
    /// - Given: An events API set up with appropriate authorization
    /// - When: An event is published over a channel with segment containing > 50 characters
    /// - Then: The operation should fail
    func testChannelSegmentCharacterLimitPublishFailure() async throws {
        guard let events = events,
              let _ = endpointURL,
              let apiKeyAuthorizer = apiKeyAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let channelName = "default/channel123456789123456789123456789123456789123456789123456789"
        let restClient = events.createRestClient(publishAuthorizer: apiKeyAuthorizer)
        let event = JSONValue(stringLiteral: "123")
        do {
            let _ = try await restClient.publish(
                channelName: channelName,
                event: event
            )
            XCTFail("Publish should not succeed.")
        } catch {
            XCTAssertNotNil(error)
            guard case EventsError.service(_, _, _, _) = error else {
                XCTFail("Error should be of type .service")
                return
            }
        }
    }
    
    /// - Given: An events API set up with appropriate authorization
    /// - When: An event is published over a channel with > 5 segment
    /// - Then: The operation should fail
    func testChannelSegmentCountLimitPublishFailure() async throws {
        guard let events = events,
              let _ = endpointURL,
              let apiKeyAuthorizer = apiKeyAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let channelName = "default/1/2/3/4/5"
        let restClient = events.createRestClient(publishAuthorizer: apiKeyAuthorizer)
        let event = JSONValue(stringLiteral: "123")
        do {
            let _ = try await restClient.publish(
                channelName: channelName,
                event: event
            )
            XCTFail("Publish should not succeed.")
        } catch {
            XCTAssertNotNil(error)
            guard case EventsError.service(_, _, _, _) = error else {
                XCTFail("Error should be of type .service")
                return
            }
        }
    }
    
    /// - Given: An events API set up with appropriate authorization
    /// - When: An event is published to an undefined namespace
    /// - Then: The operation should fail
    func testUndefinedNamespacePublishFailure() async throws {
        guard let events = events,
              let _ = endpointURL,
              let apiKeyAuthorizer = apiKeyAuthorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let channelName = "new/channel"
        let restClient = events.createRestClient(publishAuthorizer: apiKeyAuthorizer)
        let event = JSONValue(stringLiteral: "123")
        do {
            let _ = try await restClient.publish(
                channelName: channelName,
                event: event
            )
            XCTFail("Publish should not succeed.")
        } catch {
            XCTAssertNotNil(error)
            guard case EventsError.service(_, _, _, _) = error else {
                XCTFail("Error should be of type .service")
                return
            }
        }
    }
    
}
