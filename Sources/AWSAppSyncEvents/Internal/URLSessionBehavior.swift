//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// Internal protocol for testing purposes
protocol URLSessionBehavior {
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
    
    func finishTasksAndInvalidate()
}


