//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// REST Client implementation. Please refer to public APIs for details.
public final class EventsRestClient : RestClientBehavior {
    
    private let publishAuthorizer: AppSyncAuthorizer
    private let endpointURL: URL
    private let options: Events.RestOptions
    private let session: URLSessionBehavior
    private let logger: EventsLogger?
    
    init(endpointURL: URL,
         publishAuthorizer: AppSyncAuthorizer,
         urlSessionBehavior: URLSessionBehavior,
         options: Events.RestOptions = .init()) {
        self.endpointURL = endpointURL
        self.publishAuthorizer = publishAuthorizer
        self.options = options
        self.session = urlSessionBehavior
        self.logger = options.logger
    }
    
    // MARK: - Public APIs
    
    /// Publish a single event to a channel over REST POST.
    ///
    ///@param channelName of the channel to publish to.
    /// - Parameters:
    ///   - channelName: channelName of the channel to publish to.
    ///   - event: event formatted in `JSONValue`.
    ///   - authorizer: authorizer for the publish call. If not provided, the client default publishAuthorizer will be used.
    /// - Returns: Result of publish call
    public func publish(channelName: String,
                        event: JSONValue,
                        authorizer: AppSyncAuthorizer? = nil) async throws -> PublishResult {
        return try await publish(channelName: channelName,
                                 events: [event],
                                 authorizer: authorizer)
    }

    /// Publish multiple events (up to 5) to a channel over REST POST.
    /// - Parameters:
    ///   - channelName: channelName of the channel to publish to.
    ///   - events: events list of formatted `JSONValue` events.
    ///   - authorizer: authorizer for the publish call. If not provided, the client default publishAuthorizer will be used.
    /// - Returns: Result of publish call
    public func publish(channelName: String,
                        events: [JSONValue],
                        authorizer: AppSyncAuthorizer? = nil) async throws -> PublishResult {
        // create payload and send it over http client with auth headers
        var jsonEventsString: [String] = []
        for event in events {
            do {
                let jsonData = try JSONEncoder().encode(event)
                guard let jsonEventString = String.init(data: jsonData, encoding: .utf8) else {
                    throw EventsError.unknown("Invalid JSON. Please check if the events are in a valid JSON format.")
                }
                jsonEventsString.append(jsonEventString)
            }  catch let eventsError as EventsError {
                throw eventsError
            } catch {
                throw EventsError.unknown("Invalid JSON. Please check underlying error.", error)
            }
        }
        
        let eventsPostBody = EventsPostBody(channel: channelName, events: jsonEventsString)
        
        let url = EventsEndpointHelper.appSyncHTTPEndpoint(endpointURL)
        var urlrequest = URLRequest(url: url)
        
        // decorate the request with the prepend custom interceptor, if any
        urlrequest = try await options.interceptor?.intercept(urlrequest) ?? urlrequest
        
        urlrequest.setValue("application/json", forHTTPHeaderField: "content-type")
        urlrequest.setValue("application/json", forHTTPHeaderField: "accept")
        urlrequest.setValue(await PackageInfo.userAgent, forHTTPHeaderField: "x-amz-user-agent")
        urlrequest.setValue(url.host, forHTTPHeaderField: "host")
        urlrequest.httpMethod = "POST"
        
        let httpBody = try JSONEncoder().encode(eventsPostBody)
        urlrequest.httpBody = httpBody
        
        let headers = try await (authorizer ?? self.publishAuthorizer).getAuthorizationHeaders(request: urlrequest)
        for (key, value) in headers {
            urlrequest.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data,response) = try await session.data(for: urlrequest)
        guard let response = response as? HTTPURLResponse else {
            throw EventsError.service("Unknown HTTP error", "An unknown HTTP error occurred.", "Please try again.")
        }
        
        guard (200...299).contains(response.statusCode) else {
            throw EventsError.service(
                "HTTP Error code: \(response.statusCode)",
                "HTTP error description : \(HTTPURLResponse.localizedString(forStatusCode: response.statusCode))",
                "Please check the status code for more details.")
        }
        
        let decodedResult = try JSONDecoder().decode(EventsPostResult.self, from: data)
        return PublishResult(successfulEvents: decodedResult.successful ?? [],
                             failedEvents: decodedResult.failed ?? [])
    }
    
    // MARK: - Deinit
    
    deinit {
        session.finishTasksAndInvalidate()
    }
}

extension URLSession: URLSessionBehavior { }
