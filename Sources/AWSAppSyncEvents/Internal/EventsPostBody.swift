//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

struct EventsPostBody: Codable {
    let channel: String
    let events: [String]? // stringified JSON value
}
