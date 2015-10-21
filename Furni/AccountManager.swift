//
// Copyright (C) 2015 Twitter, Inc. and other contributors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//         http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import DigitsKit
import TwitterKit
import AWSCognito
import Crashlytics

enum Service: String {
    case Digits = "www.digits.com"
    case Twitter = "api.twitter.com"
}

final class AccountManager {
    static func setUpDefaultAccountManager(accountManager: AccountManager) {
        defaultAccountManager = accountManager
    }

    static var defaultAccountManager: AccountManager!

    // Configure Cognito region and identity pool.
    private static let CognitoRegionType = AWSRegionType.USEast1
    private static let CognitoIdentityPoolID = "us-east-1:ff51fd44-1b2a-4ee6-978c-24537ad50c92"

    // Setup the Cognito credentials provider.
    private let credentialProvider = AWSCognitoCredentialsProvider(regionType: AccountManager.CognitoRegionType, identityPoolId: AccountManager.CognitoIdentityPoolID)

    private let syncClient: AWSCognito

    private let awsServiceManager: AWSServiceManager

    // Twitter identity.
    var twitterIdentity: TWTRSession? {
        didSet {
            self.updateSessionOfService(.Twitter, withSession: twitterIdentity)

            self.storeSessionDataInCognitoWithProperties([
                "twitterUserID": twitterIdentity?.userID ?? "",
                "twitterUserName": twitterIdentity?.userName ?? ""
            ])

            self.updateUser()
        }
    }

    // Digits identity.
    var digitsIdentity: DGTSession? {
        didSet {
            self.updateSessionOfService(.Digits, withSession: digitsIdentity)

            self.storeSessionDataInCognitoWithProperties([
                "digitsUserID": digitsIdentity?.userID ?? "",
                "digitsPhoneNumber": digitsIdentity?.phoneNumber ?? ""
            ])

            self.updateUser()
        }
    }

    init() {
        self.awsServiceManager = AWSServiceManager.defaultServiceManager()

        let configuration = AWSServiceConfiguration(region: AccountManager.CognitoRegionType, credentialsProvider: self.credentialProvider)
        self.awsServiceManager.defaultServiceConfiguration = configuration

        self.syncClient = AWSCognito.defaultCognito()

        self.restoreSessions()
    }

    var isUserLoggedIn: Bool {
        return self.twitterIdentity != nil || self.digitsIdentity != nil
    }

    var user: User?
    private var cognitoID: String? {
        didSet {
            user?.cognitoID = cognitoID
            authenticatedAPI = cognitoID.map(AuthenticatedFurniAPI.init)
        }
    }

    var authenticatedAPI: AuthenticatedFurniAPI? {
        didSet {
            registerUser() { _ in
                self.updateFavoriteProducts()
            }
        }
    }

    func authenticateWithService(service: Service, completion: (success: Bool) -> ()) {
        switch service {
            case .Twitter: self.authenticateWithTwitter(completion: completion)
            case .Digits: self.authenticateWithDigits(completion: completion)
        }
    }

    var hasUploadedContacts: Bool = false

    // Upload the Address Book contacts. This requires a Digits session.
    func uploadContacts(completion: Bool -> ()) {
        let contacts = DGTContacts(userSession: self.digitsIdentity!)

        // Start the contacts upload. The first time, Digits will display a modal UI
        // requesting permission to upload the user’s Address Book.
        contacts.startContactsUploadWithDigitsAppearance(DGTAppearance.furniAppearance, presenterViewController: nil, title: nil) { result, error in
            // Inspect results and error objects to determine if upload succeeded.
            guard let result = result else {
                print("Error getting friends: \(error)")
                completion(false)
                return
            }

            print("Your \(result.numberOfUploadedContacts) contacts have been successfully uploaded to Digits.")
            self.hasUploadedContacts = true

            // Note: For this demo app, we only make one request,
            // since we know the number of friends will be small.
            // A production app should batch the requests using nextCursor.
            contacts.lookupContactMatchesWithCursor(nil) { matches, nextCursor, error in
                guard let matches = matches as? [DGTUser] else {
                    print("Error looking up contacts: \(error)")
                    completion(false)
                    return
                }

                // We can then do something with these Digits friends,
                // for instance post them to our API.
                self.authenticatedAPI!.uploadDigitsFriends(digitsUserIDs: matches.map { $0.userID }, completion: completion)
            }
        }
    }

    func signOut() {
        if self.digitsIdentity != nil {
            Digits.sharedInstance().logOut()
        }

        if let twitterSession = self.twitterIdentity {
            Twitter.sharedInstance().sessionStore.logOutUserID(twitterSession.userID)
        }

        self.user = nil
        self.authenticatedAPI = nil
    }

    // MARK: Private

    private var sessions: [Service : TWTRAuthSession] = [:] {
        didSet {
            self.updateCognitoID()
        }
    }

    // Both Twitter and Digits session conform to the `TWTRAuthSession` protocol.
    private func updateSessionOfService(service: Service, withSession session: TWTRAuthSession?) {
        if let session = session {
            self.sessions[service] = session
        } else {
            self.sessions.removeValueForKey(service)
        }
    }

    private static let CognitoDataSetName = "dataset"
    private func storeSessionDataInCognitoWithProperties(properties: [String : String]) {
        // Save extra information in the dataset.
        let dataset = self.syncClient.openOrCreateDataset(AccountManager.CognitoDataSetName)
        properties.forEach { key, value in
            dataset.setString(value, forKey: key)
        }

        // Synchronize the dataset.
        dataset.synchronize().continueWithBlock { task in
            if let error = task.error {
                print("Error storing credentials: \(error)")
            } else {
                print("Cognito Sync success")
            }
            return nil
        }
    }

    private func updateCognitoID() {
        // Update the logins in the credential provider.
        self.credentialProvider.logins = sessions.reduce([:]) { (var dictionary, pair) in
            dictionary[pair.0.rawValue] = "\(pair.1.authToken);\(pair.1.authTokenSecret)"
            return dictionary
        }

        // Keep a reference on the Cognito ID.
        self.credentialProvider.refresh().continueWithBlock() { task in
            dispatch_async(dispatch_get_main_queue()) {
                self.cognitoID = self.credentialProvider.identityId
            }

            return nil
        }
    }

    private func restoreSessions() {
        self.twitterIdentity = Twitter.sharedInstance().session()
        self.digitsIdentity = Digits.sharedInstance().session()
    }

    private func updateUser() {
        guard self.isUserLoggedIn else {
            self.user = nil
            return
        }

        let user = User()
        user.twitterUserID = self.twitterIdentity?.userID
        user.twitterUsername = self.twitterIdentity?.userName
        user.digitsUserID = self.digitsIdentity?.userID
        user.digitsPhoneNumber = self.digitsIdentity?.phoneNumber
        user.cognitoID = self.cognitoID

        user.populateWithLocalContact()

        self.user = user

        registerUser() { _ in
            self.updateFavoriteProducts()
        }
    }

    // Note: This is a naive implementation for demo purposes.
    private func updateFavoriteProducts() {
        guard let user = self.user else { return }
        guard user.favorites.isEmpty else { return }

        authenticatedAPI?.userFavoriteProducts() { products in
            user.favorites = products ?? []
        }
    }

    private func registerUser(completion: Bool -> () = { _ in }) {
        authenticatedAPI?.registerUser(self.digitsIdentity?.userID, digitsPhoneNumber: self.digitsIdentity?.phoneNumber, completion: completion)
    }

    private func authenticateWithTwitter(completion completion: (success: Bool) -> ()) {
        Twitter.sharedInstance().logInWithCompletion { session, error in
            if let session = session {
                self.twitterIdentity = session

                // Tie crashes to a Twitter user ID and username in Crashlytics.
                Crashlytics.sharedInstance().setUserIdentifier(session.userID)
                Crashlytics.sharedInstance().setUserName(session.userName)

                // Log Twitter Login Event in (success) Answers.
                Answers.logLoginWithMethod("Twitter", success: true, customAttributes: ["User ID" : session.userID])

                completion(success: true)
            } else if let error = error {
                // Log Twitter Login Event in (failure) Answers.
                Answers.logLoginWithMethod("Twitter", success: false, customAttributes: ["Error" : error.localizedDescription])

                completion(success: false)
            }
        }
    }

    private func authenticateWithDigits(completion completion: (success: Bool) -> ()) {
        let configuration = DGTAuthenticationConfiguration(accountFields: DGTAccountFields.Email)
        configuration.appearance = DGTAppearance.furniAppearance
        Digits.sharedInstance().authenticateWithViewController(nil, configuration: configuration) { session, error in
            if let session = session {
                self.digitsIdentity = session

                // Tie crashes to a Digits user ID in Crashlytics.
                Crashlytics.sharedInstance().setUserIdentifier(session.userID)

                // Log Digits Login Event (success) in Answers.
                Answers.logLoginWithMethod("Digits", success: true, customAttributes: ["User ID" : session.userID])

                completion(success: true)
            }
            else if let error = error {
                // Log Digits Login Event (failure) in Answers.
                Answers.logLoginWithMethod("Digits", success: false, customAttributes: ["Error" : error.localizedDescription])

                completion(success: false)
            }
        }
    }
}