//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation

extension Events {
    
    /// Options class for `EventsRestClient`, allowing optional customizations
    public struct RestOptions {
        let urlSessionConfiguration: URLSessionConfiguration?
        let logger: EventsLogger?
        let interceptor: URLRequestInterceptor?
        
        /// - Parameters:
        ///   - urlSessionConfiguration: custom `URLConfiguration` object used to initialize `URLSession` used for REST calls
        ///   - logger: allows the client to emit logs to your custom logger
        ///   - interceptor: add any prepend interceptor headers before REST call is made
        public init(urlSessionConfiguration: URLSessionConfiguration? = nil,
                    logger: EventsLogger? = nil,
                    interceptor: URLRequestInterceptor? = nil) {
            self.urlSessionConfiguration = urlSessionConfiguration
            self.logger = logger
            self.interceptor = interceptor
        }
        
        public static var `default` : RestOptions {
            .init()
        }
    }
    
    /// Options class for all EventsWebSocketClient, allowing optional customizations
    public struct WebSocketOptions {
        let urlSessionConfiguration: URLSessionConfiguration?
        let logger: EventsLogger?
        let interceptor: URLRequestInterceptor?
        
        /// - Parameters:
        ///   - urlSessionConfiguration: custom `URLConfiguration` object used to initialize `URLSession` used for websocket connection
        ///   - logger: allows the client to emit logs to your custom logger
        ///   - interceptor: add any prepend interceptor headers during websocket handshake
        public init(urlSessionConfiguration: URLSessionConfiguration? = nil,
                    logger: EventsLogger? = nil,
                    interceptor: URLRequestInterceptor? = nil) {
            self.urlSessionConfiguration = urlSessionConfiguration
            self.logger = logger
            self.interceptor = interceptor
        }
        
        public static var `default` : WebSocketOptions {
            .init()
        }
    }
}
