//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public typealias ErrorType = String
public typealias ErrorCode = UInt8
public typealias StatusCode = Int
public typealias ErrorDescription = String
public typealias RecoverySuggestion = String

protocol EventsErrorBehavior: LocalizedError {
    var errorDescription: ErrorDescription { get }
    var recoverySuggestion: RecoverySuggestion { get }
    var underlyingError: Error? { get }
    var debugDescription: ErrorDescription { get }
    init(errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion, error: Error)
}
