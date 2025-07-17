//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine

/// Web Socket Client implementation. Please refer to public APIs for details.
public final class EventsWebSocketClient : WebSocketClientBehavior {
    
    private let endpointURL: URL
    private let options: Events.WebSocketOptions
    private let connectAuthorizer: AppSyncAuthorizer
    private let subscribeAuthorizer: AppSyncAuthorizer
    private let publishAuthorizer: AppSyncAuthorizer
    private let logger: EventsLogger?
    
    private let lock = NSLock()
    
    // NOTE: Use lock for mutation of variables
    private var appSyncWebSocketClient: AppSyncWebSocketClient
    private var cancellable: AnyCancellable?
    private var tasks: Set<AnyCancellable>
    private var dataStreams = [
        String: (AsyncThrowingStream<JSONValue, Error>,
                 AsyncThrowingStream<JSONValue, Error>.Continuation)
    ]()
    private var eventStreams = [
        String: (AsyncThrowingStream<AppSyncWebSocketEventMessage, Error>,
                 AsyncThrowingStream<AppSyncWebSocketEventMessage, Error>.Continuation)
    ]()
    
    init(
        endpointURL: URL,
        connectAuthorizer: AppSyncAuthorizer,
        publishAuthorizer: AppSyncAuthorizer,
        subscribeAuthorizer: AppSyncAuthorizer,
        options: Events.WebSocketOptions
    ) {
        self.endpointURL = endpointURL
        self.connectAuthorizer = connectAuthorizer
        self.publishAuthorizer = publishAuthorizer
        self.subscribeAuthorizer = subscribeAuthorizer
        self.options = options
        self.logger = options.logger
        let configuration = options.urlSessionConfiguration ?? .default
        // set min/max tls version
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        configuration.tlsMaximumSupportedProtocolVersion = .TLSv13
        // disable caching
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        self.appSyncWebSocketClient = AppSyncWebSocketClient(
            endpointURL: endpointURL,
            connectAuthorizer: connectAuthorizer,
            publishAuthorizer: publishAuthorizer,
            subscribeAuthorizer: subscribeAuthorizer,
            options: .init(
                urlSessionConfiguration: configuration,
                logger: options.logger,
                interceptor: options.interceptor))
        self.tasks = Set()
        subscribeToAppSyncResponse()
    }
    
    // MARK: - Public APIs
    
    /// Subscribe to a channel.
    /// - Parameters:
    ///   - channelName: channelName of the channel to subscribe to.
    ///   - authorizer: authorizer for the subscribe call. The `subscribeAuthorizer` passed to the client will be used as default.
    /// - Returns: `AsyncThrowingStream` of event messages. Use a `Task` to iterate on the stream of events.
    public func subscribe(channelName: String,
                          authorizer: AppSyncAuthorizer? = nil) throws -> AsyncThrowingStream<JSONValue, Error> {
        let id = UUID().uuidString
        let (dataStream, dataStreamContinuation) = AsyncThrowingStream.makeStream(of: JSONValue.self)
        self.lock.withLock {
            dataStreams[id] = (dataStream, dataStreamContinuation)
        }
        dataStreamContinuation.onTermination = { reason in
            switch reason {
            case .cancelled:
                let task = Task {
                    do {
                        try await self.unsubscribe(id: id)
                    } catch {
                        self.logger?.verbose("Unsubscribe failure for \(channelName) : \(error)")
                    }
                }
                self.tasks.insert(task.toAnyCancellable)
            case .finished(let error) :
                guard let error = error else {
                    break
                }
                dataStreamContinuation.yield(with: .failure(error))
            @unknown default:
                break
            }
        }
        
        let (subscribeStream, subscribeContinuation) = AsyncThrowingStream.makeStream(of: AppSyncWebSocketEventMessage.self)
        subscribeContinuation.onTermination = { reason in
            self.logger?.verbose("[EventsWebSocketClient] Internal subscribe stream termination for \(id)")
            switch reason {
            case .cancelled:
                dataStreamContinuation.finish()
                _ = self.lock.withLock {
                    self.dataStreams.removeValue(forKey: id)
                }
            case .finished(let error) :
                guard let error = error else {
                    dataStreamContinuation.finish()
                    _ = self.lock.withLock {
                        self.dataStreams.removeValue(forKey: id)
                    }
                    return
                }
                dataStreamContinuation.yield(with: .failure(error))
            @unknown default:
                break
            }
        }
        
        self.lock.withLock {
            eventStreams[id] = (subscribeStream, subscribeContinuation)
        }

        let task = Task {
            do {
                self.logger?.verbose("[EventsWebSocketClient] Starting task for \(id)")
                try await self.appSyncWebSocketClient.subscribe(
                    id: id,
                    channel: channelName,
                    authorizer: authorizer
                )
                
                for try await result in subscribeStream {
                    if let _ = result as? SubscribeSuccess {
                        self.logger?.verbose("[EventsWebSocketClient] Subscribe success for \(channelName)")
                        continue
                    }
                    
                    // subscribe error
                    if let subscribeError = result as? SubscribeError,
                       let actualError = subscribeError.errors?.first {
                        self.logger?.verbose("[EventsWebSocketClient] Subscribe error for \(channelName)")
                        throw EventsError.service(actualError.errorType ?? "",
                                                  actualError.message ?? "",
                                                  "Please check your error message for details.",
                                                  actualError)
                    }
                    
                    // data received
                    if let data = result as? SubscribeData {
                        guard let jsonValue = try? JSONDecoder().decode(JSONValue.self, from: Data(data.event.utf8)) else {
                            self.logger?.verbose("[EventsWebSocketClient] Unable to decode received data")
                            return
                        }
                        dataStreamContinuation.yield(jsonValue)
                    }
                    
                    // broadcast error
                    if let broadcastError = result as? BroadcastError,
                       let actualError = broadcastError.errors?.first {
                        let error = EventsError.service(actualError.errorType ?? "",
                                                        actualError.message ?? "" ,
                                                        "Please check your error message for details.",
                                                        actualError)
                        dataStreamContinuation.yield(with: .failure(error))
                    }
                    
                    // unsubscribe success
                    if result is UnsubscribeSuccess {
                        self.logger?.verbose("[EventsWebSocketClient] Unsubscribe success for \(channelName)")
                        dataStreamContinuation.finish()
                        subscribeContinuation.finish()
                        self.lock.withLock {
                            self.dataStreams.removeValue(forKey: id)
                            self.eventStreams.removeValue(forKey: id)
                        }
                    }
                    
                    // unsubscribe error
                    if let unsubscribeError = result as? UnsubscribeError {
                        self.logger?.verbose("[EventsWebSocketClient] Unsubscribe failure for \(channelName): \(unsubscribeError)")
                        subscribeContinuation.finish()
                        _ = self.lock.withLock {
                            self.eventStreams.removeValue(forKey: id)
                        }
                    }
                    
                    // error
                    if let appSyncError = result as? AppSyncError,
                       let actualError = appSyncError.errors?.first {
                        self.logger?.verbose("[EventsWebSocketClient] Subscription failure for \(channelName): \(actualError)")
                        throw EventsError.service(
                            actualError.errorType ?? "",
                            actualError.message ?? "",
                            "Please check your error message for details.",
                            actualError)
                    }
                }
            } catch let eventsError as EventsError {
                dataStreamContinuation.yield(with: .failure(eventsError))
            } catch {
                dataStreamContinuation.yield(with: .failure(EventsError.unknown("An unknown error occurred. Please check underlying error for details.", error)))
            }
        }
        
        _ = self.lock.withLock {
            tasks.insert(task.toAnyCancellable)
        }
        
        return dataStream
    }
    
    /// Publish a single event to a channel over WebSocket.
    /// - Parameters:
    ///   - channelName: channelName of the channel to publish to.
    ///   - event: event formatted in `JSONValue`.
    ///   - authorizer: authorizer for the publish call. The `publishAuthorizer` passed to the client is the default value.
    /// - Returns: Result of publish.
    public func publish(channelName: String,
                        event: JSONValue,
                        authorizer: AppSyncAuthorizer? = nil) async throws -> PublishResult {
        return try await publish(
            channelName: channelName,
            events: [event],
            authorizer: authorizer)
    }
    
    ///Publish multiple events (up to 5) to a channel over WebSocket.
    /// - Parameters:
    ///   - channelName: channelName of the channel to publish to.
    ///   - events: events list of formatted `JSONValue`.
    ///   - authorizer: authorizer for the publish call. The `publishAuthorizer` passed to the client is the default value.
    /// - Returns: Result of publish.
    public func publish(channelName: String,
                        events: [JSONValue],
                        authorizer: AppSyncAuthorizer? = nil) async throws -> PublishResult {
        do {
            let id = UUID().uuidString
            let (publishStream, publishStreamContinuation) = AsyncThrowingStream.makeStream(of: AppSyncWebSocketEventMessage.self)
            self.lock.withLock {
                eventStreams[id] = (publishStream, publishStreamContinuation)
            }
            
            // send publish message over ws
            try await self.appSyncWebSocketClient.publish(
                id: id,
                channel: channelName,
                events: events,
                authorizer: authorizer)
            
            // wait for result
            for try await result in publishStream {
                if let success = result as? PublishSuccess {
                    return .init(successfulEvents: success.successful ?? [], failedEvents: success.failed ?? [])
                }
                
                if let publishError = result as? PublishError,
                   let actualError = publishError.errors?.first {
                    self.logger?.verbose("[EventsWebSocketClient] Publish failure for \(channelName): \(actualError)")
                    throw EventsError.service(
                        actualError.errorType ?? "",
                        actualError.message ?? "",
                        "Please check your error message for details.",
                        actualError)
                }
                
                if let appSyncError = result as? AppSyncError,
                   let actualError = appSyncError.errors?.first {
                    self.logger?.verbose("[EventsWebSocketClient] Publish failure for \(channelName): \(actualError)")
                    throw EventsError.service(
                        actualError.errorType ?? "",
                        actualError.message ?? "",
                        "Please check your Events API configuration.",
                        actualError)
                }
            }
        } catch let error as EventsError {
            throw error
        } catch {
            throw EventsError.unknown("An unknown error occurred. Please check underlying error for details.", error)
        }
        
        return .init(successfulEvents: [], failedEvents: [])
    }
    
    
    /// Disconnect from the websocket. This will result in all subscriptions completing.
    /// - Parameter flushEvents: flushEvents set to true (default) to allow all queued websocket messages to succeed before disconnecting.
    /// Setting to false will immediately disconnect, cancelling any in-progress or queued websocket messages
    public func disconnect(flushEvents: Bool = true) async throws {
        try await self.appSyncWebSocketClient.disconnect(flushEvents: flushEvents)
    }
    
    // MARK: - Deinit
    
    deinit {
        self.cancellable?.cancel()
        self.eventStreams.removeAll()
        self.dataStreams.removeAll()
        for task in self.tasks {
            task.cancel()
        }
        self.tasks.removeAll()
    }
    
    // MARK: - Private
    
    private func unsubscribe(id: String) async throws  {
        try await self.appSyncWebSocketClient.unsubscribe(id: id)
    }
    
    private func subscribeToAppSyncResponse() {
        self.cancellable = self.appSyncWebSocketClient.publisher
            .handleEvents(receiveOutput: { _ in } )
            .sink { [weak self] event in
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
                            self?.eventStreams[message.id]?.1.yield(message)
                        }
                    case "publish_error":
                        if let message = try? JSONDecoder().decode(PublishError.self, from: data){
                            self?.eventStreams[message.id]?.1.yield(message)
                        }
                    case "subscribe_success":
                        if let message = try? JSONDecoder().decode(SubscribeSuccess.self, from: data){
                            self?.eventStreams[message.id]?.1.yield(message)
                        }
                    case "subscribe_error":
                        if let message = try? JSONDecoder().decode(SubscribeError.self, from: data){
                            self?.eventStreams[message.id]?.1.yield(message)
                        }
                    case "data":
                        if let message = try? JSONDecoder().decode(SubscribeData.self, from: data){
                            self?.eventStreams[message.id]?.1.yield(message)
                        }
                    case "broadcast_error":
                        if let message = try? JSONDecoder().decode(BroadcastError.self, from: data){
                            self?.eventStreams[message.id]?.1.yield(message)
                        }
                    case "unsubscribe_success":
                        if let message = try? JSONDecoder().decode(UnsubscribeSuccess.self, from: data){
                            self?.eventStreams[message.id]?.1.yield(message)
                        }
                    case "unsubscribe_error":
                        if let message = try? JSONDecoder().decode(UnsubscribeError.self, from: data){
                            self?.eventStreams[message.id]?.1.yield(message)
                        }
                    case "error":
                        if let message = try? JSONDecoder().decode(AppSyncError.self, from: data){
                            self?.eventStreams[message.id]?.1.yield(message)
                        }
                    default:
                        break
                    }
                case .disconnected(let closeCode, let reason):
                    let error = EventsError.network("Connection close with code: \(closeCode) and reason: \(String(describing: reason))", "Please check error message.")
                    guard let self = self else { return }
                    for key in self.eventStreams.keys {
                        self.eventStreams[key]?.1.yield(with: .failure(error))
                    }
                    break
                case .connected:
                    self?.logger?.verbose("[EventsWebSocketClient] Websocket is connected")
                    break
                case .error(let error):
                    guard let self = self else { return }
                    guard let error = error as? AppSyncWebSocketClient.AppSyncWebSocketClientError else {
                        let error = EventsError.unknown("An unknown error occurred. Please check underlying error for details.", error)
                        for key in self.eventStreams.keys {
                            self.eventStreams[key]?.1.yield(with: .failure(error))
                        }
                        return
                    }
                    
                    var appSyncWebSocketClientError : Error?
                    switch error {
                    case .connectionLost:
                        appSyncWebSocketClientError = EventsError.network("Connection was lost.", "Please check your internet connection.")
                        break
                    case .connectionCancelled:
                        appSyncWebSocketClientError = EventsError.network("Connection was cancelled.", "Please try again.")
                    }
                    
                    guard let appSyncWebSocketClientError = appSyncWebSocketClientError else { return }
                    for key in self.eventStreams.keys {
                        self.eventStreams[key]?.1.yield(with: .failure(appSyncWebSocketClientError))
                    }
                    break
                default:
                    break
                }
            }
    }
    
}

fileprivate extension Task {
    var toAnyCancellable: AnyCancellable {
        AnyCancellable {
            if !self.isCancelled {
                self.cancel()
            }
        }
    }
}
