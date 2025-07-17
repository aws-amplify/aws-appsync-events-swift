//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@preconcurrency import Foundation
import os

/// A custom logger protocol which can be implemented and passed
/// in `RestOptions` or `WebSocketOptions`. The REST client / Websocket client
/// will emit logs to this object, if set
public protocol EventsLogger {

    /// The log level of the logger.
    var logLevel: LogLevel { get set }

    /// Logs a message at `error` level
    func error(_ message: @autoclosure () -> String)

    /// Logs the error at `error` level
    func error(_ error: @autoclosure () -> Error)

    /// Logs a message at `warn` level
    func warn(_ message: @autoclosure () -> String)

    /// Logs a message at `info` level
    func info(_ message: @autoclosure () -> String)

    /// Logs a message at `debug` level
    func debug(_ message: @autoclosure () -> String)

    /// Logs a message at `verbose` level
    func verbose(_ message: @autoclosure () -> String)
}


/// An enumeration of the different levels of logging.
/// The levels are progressive, with lower-value items being lower priority
/// than higher-value items. For example, `info` is lower priority than `warn`
/// or `error`.
public enum LogLevel: Int {
    case error
    case warn
    case info
    case debug
    case verbose
}
