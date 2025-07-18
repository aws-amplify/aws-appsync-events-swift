//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct AppSyncWebSocketError: Error, Codable {
    let errorType: String?
    let message: String?
}
