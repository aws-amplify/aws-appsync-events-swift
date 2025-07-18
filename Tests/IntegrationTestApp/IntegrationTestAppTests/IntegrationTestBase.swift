//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSAppSyncEvents
import AWSCognitoAuthPlugin
import AWSPluginsCore
import Combine
import XCTest

class IntegrationTestBase: XCTestCase {
    let email = "test-\(UUID().uuidString)@amazon.com"
    let password = "Password1$\(UUID().uuidString)"
    let timeoutInSeconds = TimeInterval(20)
    
    let defaultChannel = "default/channel"
    var events: Events?
    var apiKeyAuthorizer: APIKeyAuthorizer?
    var authTokenAuthorizer: AuthTokenAuthorizer?
    var iamAuthorizer: IAMAuthorizer?
    var endpointURL: URL?
    
    override func setUp() async throws {
        let (url, apiKey, region) = try loadEventsConfig()
        guard let eventsEndpoint = URL(string: url) else {
            throw EventsError.unknown("Events endpoint is invalid")
        }
        
        endpointURL = eventsEndpoint
        events = Events(endpointURL: eventsEndpoint)
        apiKeyAuthorizer = APIKeyAuthorizer(apiKey: apiKey)
        authTokenAuthorizer = AuthTokenAuthorizer(fetchLatestAuthToken: getUserPoolAccessToken)
        iamAuthorizer = IAMAuthorizer(signRequest: AppSyncEventsSigner.createAppSyncSigner(region: region))
    }
    
    func signIn() async throws {
        let session = try await Amplify.Auth.fetchAuthSession()
        guard !session.isSignedIn else {
            return
        }
        
        _ = try await AuthSignInHelper.registerAndSignInUser(
            username: email,
            password: password,
            email: email
        )
    }
    
    private func loadEventsConfig() throws -> (String, String, String) {
        if let url = Bundle.main.url(forResource: "amplify_outputs", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let object = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                if let dictionary = object as? [String: AnyObject],
                   let customFragment = dictionary["custom"] as? [String: AnyObject],
                   let eventsFragment = customFragment["events"] as? [String: String],
                   let url = eventsFragment["url"],
                   let apiKey = eventsFragment["api_key"],
                   let region = eventsFragment["aws_region"]{
                    return (url, apiKey, region)
                }
            } catch {
                throw EventsError.unknown("Unable to parse amplify_outputs.json")
            }
        }
        
        throw EventsError.unknown("amplify_outputs.json not found")
    }
    
    private func getUserPoolAccessToken() async throws -> String {
        let authSession = try await Amplify.Auth.fetchAuthSession()
        if let result = (authSession as? AuthCognitoTokensProvider)?.getCognitoTokens() {
            switch result {
            case .success(let tokens):
                return tokens.accessToken
            case .failure(let error):
                throw error
            }
        }
        throw AuthError.unknown("Did not receive a valid response from fetchAuthSession for get token.")
    }
}

extension Task {
    var toAnyCancellable: AnyCancellable {
        AnyCancellable {
            if !self.isCancelled {
                self.cancel()
            }
        }
    }
}
