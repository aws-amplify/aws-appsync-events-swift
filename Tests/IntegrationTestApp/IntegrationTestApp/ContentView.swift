//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("AWS AppSync Events Swift Integration Test App 🔧")
                .padding()
                .monospaced()
                .bold()
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 2)
                }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
