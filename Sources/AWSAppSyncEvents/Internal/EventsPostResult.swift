//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

struct EventsPostResult: Codable {
    let successful: [SuccessfulEvent]?
    let failed: [FailedEvent]?
}
