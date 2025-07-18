//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// MARK: - URLSessionWebSocketDelegate methods

extension AppSyncWebSocketClient: URLSessionWebSocketDelegate {

    enum AppSyncWebSocketClientError: Swift.Error {
        case connectionLost
        case connectionCancelled
    }

    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        self.logger?.verbose("[AppSyncWebSocketClient] Websocket connected")
        subject.send(.connected)
    }

    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        self.logger?.verbose("[AppSyncWebSocketClient] Websocket disconnected closeCode: \(closeCode) and reason : \(String(describing: reason))")
        subject.send(.disconnected(closeCode, reason.flatMap { String(data: $0, encoding: .utf8) }))
    }

    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Swift.Error?
    ) {
        guard let error else {
            self.logger?.verbose("[AppSyncWebSocketClient] URLSession didComplete")
            return
        }

        self.logger?.verbose("[AppSyncWebSocketClient] URLSession didCompleteWithError: \(error))")
        let nsError = error as NSError
        switch (nsError.domain, nsError.code) {
        case (NSURLErrorDomain.self, NSURLErrorNetworkConnectionLost), // connection lost
             (NSPOSIXErrorDomain.self, Int(ECONNABORTED)): // background to foreground
            subject.send(.error(AppSyncWebSocketClientError.connectionLost))
        case (NSURLErrorDomain.self, NSURLErrorCancelled):
            self.logger?.verbose("[AppSyncWebSocketClient] Skipping NSURLErrorCancelled error")
            subject.send(.error(AppSyncWebSocketClientError.connectionCancelled))
        default:
            subject.send(.error(error))
        }
    }
}
