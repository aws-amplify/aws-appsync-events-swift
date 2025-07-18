//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


/// Error type returned by the public APIs in `EventsRestClient` and `EventsWebSocketClient` classes
/// - Network errors like lost internet connection, web socket closure are returned with `.network` type
/// - Appsync service errors are returned with `.service` type
/// - Other errors like invalid JSON, encoding/decoding errors are returned with `.unknown` type
public enum EventsError {
    case network(ErrorDescription, RecoverySuggestion, Error? = nil)
    case service(ErrorType, ErrorDescription, RecoverySuggestion, Error? = nil)
    case unknown(ErrorDescription, Error? = nil)
}

extension EventsError: Equatable {
    
    public static func ==(lhs: EventsError, rhs: EventsError) -> Bool {
        switch(lhs, rhs) {
        case (.service(let lhsType, _, _, _), .service(let rhsType, _, _, _)):
            return lhsType == rhsType
        case (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
}

extension EventsError: EventsErrorBehavior {
    public var underlyingError: Error? {
        switch self {
        case
             .unknown(_, let underlyingError),
             .service(_, _, _, let underlyingError),
             .network(_, _, let underlyingError):
            return underlyingError

        }
    }

    public var errorDescription: ErrorDescription {
        switch self {
        case
             .unknown(let errorDescription, _),
             .service(_, let errorDescription, _, _),
             .network(_, let errorDescription, _):
            return errorDescription
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case
             .service(_, _, let recoverySuggestion, _),
             .network(_, let recoverySuggestion, _):
            return recoverySuggestion
        case .unknown:
            return "Please try again."
        }
    }

    public var debugDescription: ErrorDescription {
        let errorType = type(of: self)

        var components = ["\(errorType): \(errorDescription)"]

        if !recoverySuggestion.isEmpty {
            components.append("Recovery suggestion: \(recoverySuggestion)")
        }

        if let underlyingError = underlyingError {
            if let underlyingError = underlyingError as? EventsErrorBehavior {
                components.append("Caused by:\n\(String(describing: underlyingError.debugDescription))")
            } else {
                components.append("Caused by:\n\(underlyingError)")
            }
        }

        return components.joined(separator: "\n")
    }
    
    public init(
        errorDescription: ErrorDescription = "An unknown error occurred.",
        recoverySuggestion: RecoverySuggestion = "Please try again.",
        error: Error
    ) {
        if let error = error as? Self {
            self = error
        } else {
            self = .unknown(errorDescription, error)
        }
    }
}
