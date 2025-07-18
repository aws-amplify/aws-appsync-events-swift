//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAppSyncEvents

final class EventsEndpointHelperTests: XCTestCase {
    
    func testEventsHTTPEndpointWithAWSAppSyncDomainReturnCorrectHTTPDomain() {
        let appSyncEndpoint = URL(string: "https://abc.appsync-api.us-east-1.amazonaws.com")!
        XCTAssertEqual(
            EventsEndpointHelper.appSyncHTTPEndpoint(appSyncEndpoint),
            URL(string: "https://abc.appsync-api.us-east-1.amazonaws.com/event")
        )
    }
    
    func testEventsHTTPEndpointWithAWSAppSyncRealTimeDomainReturnCorrectHTTPDomain() {
        let appSyncEndpoint = URL(string: "wss://abc.appsync-realtime-api.us-east-1.amazonaws.com/events/realtime")!
        XCTAssertEqual(
            EventsEndpointHelper.appSyncHTTPEndpoint(appSyncEndpoint),
            URL(string: "https://abc.appsync-api.us-east-1.amazonaws.com/event")
        )
    }
    
    func testEventsHTTPEndpointWithHTTPDomainReturnTheSameDomain() {
        let appSyncEndpoint = URL(string: "https://abc.appsync-api.us-east-1.amazonaws.com/events")!
        XCTAssertEqual(
            EventsEndpointHelper.appSyncHTTPEndpoint(appSyncEndpoint),
            URL(string: "https://abc.appsync-api.us-east-1.amazonaws.com/event")
        )
    }
    
    func testEventsRealTimeEndpointWithAWSAppSyncDomainReturnCorrectRealtimeDomain() {
        let appSyncEndpoint = URL(string: "https://abc.appsync-api.us-east-1.amazonaws.com")!
        XCTAssertEqual(
            EventsEndpointHelper.appSyncRealTimeEndpoint(appSyncEndpoint),
            URL(string: "wss://abc.appsync-realtime-api.us-east-1.amazonaws.com/event/realtime")
        )
    }
    
    func testAppSyncRealTimeEndpointWithHTTPDomainReturnCorrectRealtimeDomain() {
        let appSyncEndpoint = URL(string: "https://abc.appsync-api.us-east-1.amazonaws.com/events")!
        XCTAssertEqual(
            EventsEndpointHelper.appSyncRealTimeEndpoint(appSyncEndpoint),
            URL(string: "wss://abc.appsync-realtime-api.us-east-1.amazonaws.com/event/realtime")
        )
    }

    func testAppSyncRealTimeEndpointWithAWSAppSyncRealTimeDomainReturnTheSameDomain() {
        let appSyncEndpoint = URL(string: "wss://abc.appsync-realtime-api.us-east-1.amazonaws.com/events/realtime")!
        XCTAssertEqual(
            EventsEndpointHelper.appSyncRealTimeEndpoint(appSyncEndpoint),
            URL(string: "wss://abc.appsync-realtime-api.us-east-1.amazonaws.com/event/realtime")
        )
    }
    
    // MARK: - Custom Domain
    func testAppSyncHTTPEndpointWithCustomDomainReturnCorrectHTTPDomain()  {
        let appSyncEndpoint = URL(string: "https://test.example.com")!
        XCTAssertEqual(
            EventsEndpointHelper.appSyncHTTPEndpoint(appSyncEndpoint),
            URL(string: "https://test.example.com/event")
        )
    }

    func testAppSyncRealTimeEndpointWithCustomDomainReturnCorrectRealtimePath() {
        let appSyncEndpoint = URL(string: "https://test.example.com")!
        XCTAssertEqual(
            EventsEndpointHelper.appSyncRealTimeEndpoint(appSyncEndpoint),
            URL(string: "wss://test.example.com/event/realtime")
        )
    }
}
