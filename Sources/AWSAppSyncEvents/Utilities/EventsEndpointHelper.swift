//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class EventsEndpointHelper {
    
    static func appSyncHTTPEndpoint(_ url: URL) -> URL {
        guard let host = url.host else {
            return url
        }

        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        
        // aws domain
        if let _ = urlComponents.host?.hasSuffix("amazonaws.com") {
            urlComponents.host = host.replacingOccurrences(of: "appsync-realtime-api", with: "appsync-api")
        }
        
        urlComponents.path = "/event"
        urlComponents.scheme = "https"

        guard let apiUrl = urlComponents.url else {
            return url
        }
        return apiUrl
    }

    static func appSyncRealTimeEndpoint(_ url: URL) -> URL {
        guard let host = url.host else {
            return url
        }

        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        // aws domain
        if let _ = urlComponents.host?.hasSuffix("amazonaws.com") {
            urlComponents.host = host.replacingOccurrences(of: "appsync-api", with: "appsync-realtime-api")
        }
        
        urlComponents.scheme = "wss"
        urlComponents.path = "/event/realtime"
        guard let realTimeUrl = urlComponents.url else {
            return url
        }
        return realTimeUrl
    }
}

