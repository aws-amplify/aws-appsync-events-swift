//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAppSyncEvents

class EventsRestTests: XCTestCase {
    private let channelName = "/default/channel"
    private var endpointURL: URL?
    private var authorizer: MockAPIKeyAuthorizer?
    
    override func setUp() async throws {
        endpointURL = URL(string: "https://example1234567890000.appsync-api.us-east-1.amazonaws.com")
        authorizer = MockAPIKeyAuthorizer(apiKey: "testApiKey")
    }
    
    override func tearDown() async throws {
        
    }
    
    // MARK: - Publish Success
    
    func testSingleEventPublishSuccess() async throws {
        guard let endpointURL = endpointURL,
              let authorizer = authorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let events = MockEvents(
            endpointURL: endpointURL,
            urlSessionBehavior: MockURLSessionBehavior(type: .success))
        let restClient = events.createRestClient(publishAuthorizer: authorizer, options: .default)
        do {
            let result = try await restClient.publish(
                channelName: channelName,
                event: "123",
                authorizer: authorizer
            )
            guard PublishResultStatus.success == result.status else {
                XCTFail("Publish result should be success")
                return
            }
            XCTAssertTrue(authorizer.isInvoked)
            XCTAssertEqual(result.status, .success)
            XCTAssertEqual(result.successfulEvents.count, 1)
            XCTAssertEqual(result.failedEvents.count, 0)
        } catch {
            XCTFail("Publish should succeed.")
        }
    }
    
    func testMultipleEventPublishSuccess() async throws {
        guard let endpointURL = endpointURL,
              let authorizer = authorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let events = MockEvents(
            endpointURL: endpointURL,
            urlSessionBehavior: MockURLSessionBehavior(type: .success))
        let restClient = events.createRestClient(publishAuthorizer: authorizer, options: .default)
        do {
            let result = try await restClient.publish(
                channelName: channelName,
                events: ["123"],
                authorizer: authorizer
            )
            guard PublishResultStatus.success == result.status else {
                XCTFail("Publish result should be success")
                return
            }
            XCTAssertTrue(authorizer.isInvoked)
            XCTAssertEqual(result.status, .success)
            XCTAssertEqual(result.successfulEvents.count, 1)
            XCTAssertEqual(result.failedEvents.count, 0)
        } catch {
            XCTFail("Publish should succeed.")
        }
    }
    
    // MARK: - Publish Failure
    
    func testSingleEventPublishHTTPFailure() async throws {
        guard let endpointURL = endpointURL,
              let authorizer = authorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let events = MockEvents(
            endpointURL: endpointURL,
            urlSessionBehavior: MockURLSessionBehavior(type: .failure))
        let restClient = events.createRestClient(publishAuthorizer: authorizer, options: .default)
        do {
            let _ = try await restClient.publish(
                channelName: channelName,
                event: "123",
                authorizer: authorizer
            )
            XCTFail("Publish should not succeed.")
        } catch {
            guard let error = error as? EventsError else {
                XCTFail("Error returned should be of `EventsError` type")
                return
            }
            
            guard case EventsError.service(_, _, _, _) = error else {
                XCTFail("Error returned should be of `EventsError` type")
                return
            }
        }
    }
    
    func testMultipleEventPublishHTTPFailure() async throws {
        guard let endpointURL = endpointURL,
              let authorizer = authorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let events = MockEvents(
            endpointURL: endpointURL,
            urlSessionBehavior: MockURLSessionBehavior(type: .failure))
        let restClient = events.createRestClient(publishAuthorizer: authorizer, options: .default)
        do {
            let _ = try await restClient.publish(
                channelName: channelName,
                events: ["123"],
                authorizer: authorizer
            )
            XCTFail("Publish should not succeed.")
        } catch {
            guard let error = error as? EventsError else {
                XCTFail("Error returned should be of `EventsError` type")
                return
            }
            
            guard case EventsError.service(_, _, _, _) = error else {
                XCTFail("Error returned should be of `EventsError` type")
                return
            }
        }
    }
    
    func testSingleEventPublishEncodingFailure() async throws {
        guard let endpointURL = endpointURL,
              let authorizer = authorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let events = MockEvents(
            endpointURL: endpointURL,
            urlSessionBehavior: MockURLSessionBehavior(type: .failure))
        let restClient = events.createRestClient(publishAuthorizer: authorizer, options: .default)
        do {
            let _ = try await restClient.publish(
                channelName: channelName,
                event: JSONValue(floatLiteral: Double.infinity),
                authorizer: authorizer
            )
            XCTFail("Publish should not succeed.")
        } catch {
            guard let error = error as? EventsError else {
                XCTFail("Error returned should be of `EventsError` type")
                return
            }
            
            guard case EventsError.unknown(_, _) = error else {
                XCTFail("Error returned should be of `EventsError` type")
                return
            }
        }
    }
    
    func testMultipleEventPublishEncodingFailure() async throws {
        guard let endpointURL = endpointURL,
              let authorizer = authorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let events = MockEvents(
            endpointURL: endpointURL,
            urlSessionBehavior: MockURLSessionBehavior(type: .failure))
        let restClient = events.createRestClient(publishAuthorizer: authorizer, options: .default)
        do {
            let _ = try await restClient.publish(
                channelName: channelName,
                events: [JSONValue(floatLiteral: Double.infinity)],
                authorizer: authorizer
            )
            XCTFail("Publish should not succeed.")
        } catch {
            guard let error = error as? EventsError else {
                XCTFail("Error returned should be of `EventsError` type")
                return
            }
            
            guard case EventsError.unknown(_, _) = error else {
                XCTFail("Error returned should be of `EventsError` type")
                return
            }
        }
    }
    
    func testSingleEventPublishServiceFailure() async throws {
        guard let endpointURL = endpointURL,
              let authorizer = authorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let events = MockEvents(
            endpointURL: endpointURL,
            urlSessionBehavior: MockURLSessionBehavior(type: .successWithPublishFailure))
        let restClient = events.createRestClient(publishAuthorizer: authorizer, options: .default)
        do {
            let result = try await restClient.publish(
                channelName: channelName,
                event: "123",
                authorizer: authorizer
            )
            XCTAssertTrue(authorizer.isInvoked)
            XCTAssertEqual(result.status, .failure)
            XCTAssertEqual(result.successfulEvents.count, 0)
            XCTAssertEqual(result.failedEvents.count, 1)
        } catch {
            XCTFail("Publish should succeed.")
        }
    }
    
    func testMultipleEventPublishServiceFailure() async throws {
        guard let endpointURL = endpointURL,
              let authorizer = authorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let events = MockEvents(
            endpointURL: endpointURL,
            urlSessionBehavior: MockURLSessionBehavior(type: .successWithPublishFailure))
        let restClient = events.createRestClient(publishAuthorizer: authorizer, options: .default)
        do {
            let result = try await restClient.publish(
                channelName: channelName,
                events: ["123"],
                authorizer: authorizer
            )
            XCTAssertTrue(authorizer.isInvoked)
            XCTAssertEqual(result.status, .failure)
            XCTAssertEqual(result.successfulEvents.count, 0)
            XCTAssertEqual(result.failedEvents.count, 1)
        } catch {
            XCTFail("Publish should succeed.")
        }
    }
    
    func testSingleEventPublishPartialSuccess() async throws {
        guard let endpointURL = endpointURL,
              let authorizer = authorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let events = MockEvents(
            endpointURL: endpointURL,
            urlSessionBehavior: MockURLSessionBehavior(type: .successWithPublishPartialSuccess))
        let restClient = events.createRestClient(publishAuthorizer: authorizer, options: .default)
        do {
            let result = try await restClient.publish(
                channelName: channelName,
                event: "123",
                authorizer: authorizer
            )
            XCTAssertTrue(authorizer.isInvoked)
            XCTAssertEqual(result.status, .partialSuccess)
            XCTAssertEqual(result.successfulEvents.count, 1)
            XCTAssertEqual(result.failedEvents.count, 1)
        } catch {
            XCTFail("Publish should succeed.")
        }
    }
    
    func testMultipleEventPublishPartialSuccess() async throws {
        guard let endpointURL = endpointURL,
              let authorizer = authorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let events = MockEvents(
            endpointURL: endpointURL,
            urlSessionBehavior: MockURLSessionBehavior(type: .successWithPublishPartialSuccess))
        let restClient = events.createRestClient(publishAuthorizer: authorizer, options: .default)
        do {
            let result = try await restClient.publish(
                channelName: channelName,
                events: ["123"],
                authorizer: authorizer
            )
            XCTAssertTrue(authorizer.isInvoked)
            XCTAssertEqual(result.status, .partialSuccess)
            XCTAssertEqual(result.successfulEvents.count, 1)
            XCTAssertEqual(result.failedEvents.count, 1)
        } catch {
            XCTFail("Publish should succeed.")
        }
    }
    
    // MARK: - URLRequestInterceptor
    
    func testSingleEventPublishURLRequestInterceptorCalled() async throws {
        guard let endpointURL = endpointURL,
              let authorizer = authorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let events = MockEvents(
            endpointURL: endpointURL,
            urlSessionBehavior: MockURLSessionBehavior(type: .success))
        let urlRequestInterceptorCalledExpectation = expectation(description: "URLRequestInterceptor should be called")
        let restClient = events.createRestClient(
            publishAuthorizer: authorizer,
            options: .init(interceptor: MockRestURLRequestInterceptor(
                expectation: urlRequestInterceptorCalledExpectation)))
        do {
            let _ = try await restClient.publish(
                channelName: channelName,
                event: "123",
                authorizer: authorizer
            )
        } catch {
            XCTFail("Publish should succeed.")
        }
        
        await fulfillment(of: [urlRequestInterceptorCalledExpectation], timeout: 5)
    }
    
    func testMultipleEventPublishURLRequestInterceptorCalled() async throws {
        guard let endpointURL = endpointURL,
              let authorizer = authorizer else {
            XCTFail("Invalid URL/authorizer")
            return
        }
        
        let events = MockEvents(
            endpointURL: endpointURL,
            urlSessionBehavior: MockURLSessionBehavior(type: .success))
        let urlRequestInterceptorCalledExpectation = expectation(description: "URLRequestInterceptor should be called")
        let restClient = events.createRestClient(
            publishAuthorizer: authorizer,
            options: .init(interceptor: MockRestURLRequestInterceptor(
                expectation: urlRequestInterceptorCalledExpectation)))
        do {
            let _ = try await restClient.publish(
                channelName: channelName,
                events: ["123"],
                authorizer: authorizer
            )
        } catch {
            XCTFail("Publish should succeed.")
        }
        
        await fulfillment(of: [urlRequestInterceptorCalledExpectation], timeout: 5)
    }
    
}
