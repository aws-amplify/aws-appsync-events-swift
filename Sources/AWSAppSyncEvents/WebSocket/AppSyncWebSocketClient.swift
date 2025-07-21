//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation

/// Internal implementation for `WebSocket` connection for
/// Appsync Event APIs
final class AppSyncWebSocketClient: NSObject, URLSessionDelegate {
    
    var request: URLRequest
    var publisher: AnyPublisher<AppSyncWebSocketEvent, Never> {
        return subject.eraseToAnyPublisher()
    }
    
    /// Internal writable WebSocketEvent data stream
    let subject = PassthroughSubject<AppSyncWebSocketEvent, Never>()
    
    // MARK: - Internal
    
    private var session: URLSession?
    private let options: Events.WebSocketOptions
    let logger: EventsLogger?
    
    /// The underlying URLSessionWebSocketTask
    private var connection: URLSessionWebSocketTask? {
        willSet {
            connection?.cancel(with: .goingAway, reason: nil)
        }
    }
    
    // Queue to serialize web socket calls
    private let taskQueue: TaskQueue<Void>
    
    // Handle connection timeout
    private let heartBeatsMonitor = PassthroughSubject<Void, Never>()
    private var heartBeatMonitorCancellable: AnyCancellable?
    
    // Options related to websocket connect call
    private let delegateQueue: OperationQueue
    private var urlSessionConfiguration: URLSessionConfiguration?
    private var urlRequestInterceptor: URLRequestInterceptor? = nil

    /// Authorizers for appending authentication headers to web socket calls
    private var connectAuthorizer: AppSyncAuthorizer
    private var subscribeAuthorizer: AppSyncAuthorizer
    private var publishAuthorizer: AppSyncAuthorizer

    init(
        endpointURL: URL,
        connectAuthorizer: AppSyncAuthorizer,
        publishAuthorizer: AppSyncAuthorizer,
        subscribeAuthorizer: AppSyncAuthorizer,
        callbackQueue: DispatchQueue = .main,
        options: Events.WebSocketOptions = .default
    ) {
        self.request = URLRequest(url: endpointURL)
        self.connectAuthorizer = connectAuthorizer
        self.publishAuthorizer = publishAuthorizer
        self.subscribeAuthorizer = subscribeAuthorizer
        self.options = options
        self.logger = options.logger
        
        // set up internal queues
        self.taskQueue = TaskQueue()
        self.delegateQueue = OperationQueue()
        self.delegateQueue.maxConcurrentOperationCount = 1
    }
    
    func subscribe(id: String,
                   channel: String,
                   authorizer: (any AppSyncAuthorizer)? = nil) async throws {
        try await taskQueue.sync {
            try await self.connect()
            
            guard let url = self.request.url else {
                throw EventsError.network(
                    "The provided appsync URL is not valid.",
                    "Please check if the provided URL is correct")
            }
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .withoutEscapingSlashes
            let eventsPostBody = EventsPostBody(channel: channel, events: nil)
            
            var requestToSign = try self.getRequestToSign(url: url)
            requestToSign.httpBody = try encoder.encode(eventsPostBody)
            
            let authHeaders = try await (authorizer ?? self.subscribeAuthorizer).getAuthorizationHeaders(request: requestToSign)
            let message = SubscribeMessage(
                type: "subscribe",
                id: id,
                channel: channel,
                authorization: authHeaders)
            
            guard let encodedjsonData = try? JSONEncoder().encode(message),
                  let jsonString = String(data: encodedjsonData, encoding: .utf8)
            else {
                throw EventsError.unknown("Error in encoding JSON data for websocket subscribe message.")
            }
            try await self.connection?.send(.string(jsonString))
        }
    }
    
    func unsubscribe(id: String) async throws  {
        try await taskQueue.sync {
            self.logger?.verbose("[AppSyncWebSocketClient] unsubscribe")
            guard self.connection?.state == .running else {
                let message = "Client should be in connected state to send unsubscribe"
                self.logger?.verbose("[AppSyncWebSocketClient] \(message)")
                throw EventsError.unknown(message, nil)
            }
            
            let message = UnsubscribeMessage(
                type: "unsubscribe",
                id: id)
            
            guard let encodedjsonData = try? JSONEncoder().encode(message),
                  let jsonString = String(data: encodedjsonData, encoding: .utf8)
            else {
                throw EventsError.unknown("Error in encoding JSON data for websocket unsubscribe message.")
            }
            
            try await self.connection?.send(.string(jsonString))
        }
    }
    
    func publish(id: String,
                 channel: String,
                 event: JSONValue,
                 authorizer: (any AppSyncAuthorizer)? = nil) async throws {
        try await publish(
            id: id,
            channel: channel,
            events: [event])
    }
    
    func publish(id: String,
                 channel: String,
                 events: [JSONValue],
                 authorizer: (any AppSyncAuthorizer)? = nil) async throws {
        try await taskQueue.sync {
            try await self.connect()
            
            guard let url = self.request.url else {
                throw EventsError.network(
                    "The provided appsync URL is not valid.",
                    "Please check if the provided URL is correct")
            }
            
            var jsonEventsString: [String] = []
            for event in events {
                let jsonData = try JSONEncoder().encode(event)
                let jsonEventString = String.init(data: jsonData, encoding: .utf8)!
                jsonEventsString.append(jsonEventString)
            }
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .withoutEscapingSlashes
            let eventsPostBody = EventsPostBody(channel: channel, events: jsonEventsString)
            
            var requestToSign = try self.getRequestToSign(url: url)
            requestToSign.httpBody = try encoder.encode(eventsPostBody)
            
            let authHeaders = try await (authorizer ?? self.publishAuthorizer).getAuthorizationHeaders(request: requestToSign)
            let message = PublishMessage(
                type: "publish",
                id: id,
                channel: channel,
                events: jsonEventsString,
                authorization: authHeaders)
            
            
            guard let encodedjsonData = try? JSONEncoder().encode(message),
                  let jsonString = String(data: encodedjsonData, encoding: .utf8)
            else {
                throw EventsError.unknown("Error in encoding JSON data for websocket publish message.")
            }
            try await self.connection?.send(.string(jsonString))
        }
    }
    
    func disconnect(flushEvents: Bool = true) async throws {
        try await taskQueue.sync {
            self.logger?.verbose("[AppSyncWebSocketClient] Calling Disconnect")
            self.heartBeatMonitorCancellable?.cancel()
            guard self.connection?.state == .running else {
                let message = "Client should be in connected state to trigger disconnect"
                self.logger?.verbose("[AppSyncWebSocketClient] \(message)")
                throw EventsError.unknown(message, nil)
            }
            
            if(flushEvents) {
                self.connection?.cancel(with: .normalClosure, reason: String("User initiated disconnect.").data(using: .utf8))
                self.session?.finishTasksAndInvalidate() // invalidates the session, allowing any outstanding tasks to finish.
            } else {
                self.connection?.cancel(with: .goingAway, reason: String("User initiated disconnect.").data(using: .utf8))
                self.session?.invalidateAndCancel() // cancels all outstanding tasks and then invalidates the session.
            }
        }
    }


    // MARK: - Deinit

    deinit {
        self.subject.send(completion: .finished)
        self.heartBeatMonitorCancellable?.cancel()
        self.connection?.cancel(with: .goingAway, reason: nil)
        self.session?.finishTasksAndInvalidate()
    }

    // MARK: - Private/Internal
    
    func connect() async throws {
        self.logger?.verbose("[AppSyncWebSocketClient] Calling Connect")
        guard connection?.state != .running else {
            self.logger?.verbose("[AppSyncWebSocketClient] WebSocket is already in connected state")
            return
        }
        
        self.logger?.verbose("[AppSyncWebSocketClient] Creating new connection and starting read")
        self.connection = try await createWebSocketConnection()
        
        // Perform reading from a WebSocket in a separate task recursively to
        // avoid blocking the execution.
        Task {
            await self.startReadMessage()
        }
        
        self.connection?.resume()
    }

    private func createWebSocketConnection() async throws -> URLSessionWebSocketTask {
        self.logger?.verbose("[AppSyncWebSocketClient] createWebSocketConnection")
        guard let url = request.url else {
            throw EventsError.network(
                "The provided appsync URL is not valid.",
                "Please check if the provided URL is correct")
        }
        
        // decorate the request with the prepend custom interceptor, if any
        request = try await options.interceptor?.intercept(request) ?? request
        
        var requestToSign = try getRequestToSign(url: url)
        requestToSign.httpBody = Data("{}".utf8)
        
        let authHeaders = try await connectAuthorizer.getAuthorizationHeaders(request: requestToSign)
        request.setValue("aws-appsync-event-ws", forHTTPHeaderField: "Sec-WebSocket-Protocol")
        request.setValue(requestToSign.url?.host, forHTTPHeaderField: "host")
        request.setValue(await PackageInfo.userAgent, forHTTPHeaderField: "x-amz-user-agent")
        
        // add authorization headers
        for authHeader in authHeaders {
            request.setValue(authHeader.value, forHTTPHeaderField: authHeader.key)
        }
        
        let configuration = options.urlSessionConfiguration ?? .default
        session = URLSession(
                configuration: configuration,
                delegate: self,
                delegateQueue: self.delegateQueue)
        return session!.webSocketTask(with: request)
    }
    
    /**
     Recursively read WebSocket data frames and publish to data stream.
     */
    private func startReadMessage() async {
        guard let connection = connection else {
            self.logger?.verbose("[AppSyncWebSocketClient] WebSocket connection doesn't exist")
            return
        }
        if connection.state == .canceling || connection.state == .completed {
            self.logger?.verbose("[AppSyncWebSocketClient] WebSocket connection state is \(connection.state). Stopping reading of websocket messages.")
            return
        }
        do {
            let message = try await connection.receive()
            self.logger?.verbose("[AppSyncWebSocketClient] WebSocket received message: \(String(describing: message))")
            switch message {
            case .data(let data):
                subject.send(.data(data))
            case .string(let string):
                guard let data = string.data(using: .utf8),
                      let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let type = response["type"] as? String
                else {
                    break
                }
                
                switch type {
                case "connection_ack":
                    self.logger?.verbose("[AppSyncWebSocketClient] Connection ack, starting heart beat monitoring...")
                    if let payload = response["payload"] as? [String: Any] {
                        self.monitorHeartBeat(payload)
                    }
                case "ka":
                    self.logger?.verbose("[AppSyncWebSocketClient] Keep alive")
                    self.heartBeatsMonitor.send(())
                default:
                    subject.send(.string(string))
                }
            @unknown default:
                break
            }
        } catch {
            if connection.state == .running {
                subject.send(.error(error))
            } else {
                self.logger?.verbose("[AppSyncWebSocketClient] Read message failed with connection state \(connection.state) and error: \(error)")
            }
            return
        }
        
        // recursively read websocket messages
        await startReadMessage()
    }

    private func monitorHeartBeat(_ connectionAck: [String: Any]) {
        let connectionTimeOutMs = (connectionAck["connectionTimeoutMs"] as? Int) ?? 300000
        self.logger?.verbose("[AppSyncWebSocketClient] start monitoring heart beat with interval \(String(describing: connectionTimeOutMs))")

        self.heartBeatMonitorCancellable = heartBeatsMonitor.eraseToAnyPublisher()
            .debounce(for: .milliseconds(connectionTimeOutMs), scheduler: DispatchQueue.global(qos: .userInitiated))
            .first()
            .sink { [weak self] _ in
                self?.logger?.verbose("[AppSyncWebSocketClient] Keep alive timed out, disconnecting...")
                Task { [weak self] in
                    try await self?.disconnect()
                }
            }

        self.heartBeatsMonitor.send(())
    }
    
    private func getRequestToSign(url: URL) throws -> URLRequest {
        let httpURL = EventsEndpointHelper.appSyncHTTPEndpoint(url)
        guard let host = httpURL.host else {
            throw EventsError.unknown("The provided appsync URL is not valid.")
        }
        var requestToSign = URLRequest(url: httpURL)
        requestToSign.httpMethod = "POST"
        requestToSign.setValue(host, forHTTPHeaderField: "host")
        return requestToSign
    }
}
