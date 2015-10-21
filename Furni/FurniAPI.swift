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
import Alamofire

private typealias JSONObject = [String : AnyObject]

final class FurniAPI {
    static let sharedInstance = FurniAPI()

    // API base URL.
    private let apiBaseURL = "https://vso4w24kxa.execute-api.us-east-1.amazonaws.com/prod/"

    private var cachedCollections: [Collection] = []

    func getCollectionList(completion: [Collection] -> Void) {
        if cachedCollections.count > 0 {
            completion(cachedCollections)
        }

        get("collections") { JSON in
            if let result = JSON as? JSONObject {
                let collectionArray = result["collections"] as! [JSONObject]
                var collections: [Collection] = []
                for dict in collectionArray {
                    collections.append(Collection(dictionary: dict))
                }
                self.cachedCollections = collections
                completion(collections)
            }
        }
    }

    func getCollection(permalink: String, completion: Collection -> Void) {
        let collection = self.cachedCollections.filter{ $0.permalink == permalink }.first
        if collection?.products.count > 0 {
            completion(collection!)
        }

        get("collections/" + permalink) { JSON in
            if let result = JSON as? JSONObject {
                let productArray = result["products"] as! [JSONObject]
                for productDict in productArray {
                    collection!.products.append(Product(dictionary: productDict, collectionPermalink: permalink))
                }
                completion(collection!)
            }
        }
    }

    // Convenience method to perform a GET request on an API endpoint.
    private func get(endpoint: String, completion: AnyObject? -> Void) {
        request(endpoint, method: "GET", encoding: .JSON, parameters: nil, completion: completion)
    }

    // Convenience method to perform a POST request on an API endpoint.
    private func post(endpoint: String, parameters: [String: AnyObject]?, completion: AnyObject? -> Void) {
        request(endpoint, method: "POST", encoding: .JSON, parameters: parameters, completion: completion)
    }

    // Perform a request on an API endpoint using Alamofire.
    private func request(endpoint: String, method: String, encoding: Alamofire.ParameterEncoding, parameters: [String: AnyObject]?, completion: AnyObject? -> Void) {
        let URL = NSURL(string: apiBaseURL + endpoint)!
        let URLRequest = NSMutableURLRequest(URL: URL)
        URLRequest.HTTPMethod = method

        let request = encoding.encode(URLRequest, parameters: parameters).0

        print("Starting \(method) \(URL) (\(parameters ?? [:]))")
        Alamofire.request(request).responseJSON { _, response, result in
            print("Finished \(method) \(URL): \(response?.statusCode)")
            switch result {
            case .Success(let JSON):
                completion(JSON)
            case .Failure(let data, let error):
                print("Request failed with error: \(error)")
                if let data = data {
                    print("Response data: \(NSString(data: data, encoding: NSUTF8StringEncoding)!)")
                }

                completion(nil)
            }
        }
    }
}

final class AuthenticatedFurniAPI {
    typealias CognitoID = String
    private let cognitoID: CognitoID

    init(cognitoID: CognitoID) {
        self.cognitoID = cognitoID
    }

    func registerUser(digitsUserID: String?, digitsPhoneNumber: String?, completion: Bool -> ()) {
        var parameters: JSONObject = ["cognitoId": self.cognitoID]
        if let digitsUserID = digitsUserID, let digitsPhoneNumber = digitsPhoneNumber {
            parameters["digitsId"] = digitsUserID
            parameters["phoneNumber"] = digitsPhoneNumber
        }

        FurniAPI.sharedInstance.post("users/", parameters: parameters) { response in
            let success = response != nil

            completion(success)
        }
    }

    func favoriteProduct(favorite: Bool, product: Product, completion: Bool -> ()) {
        product.isFavorited = favorite
        FurniAPI.sharedInstance.request("favorites", method: favorite ? "POST" : "DELETE", encoding: .JSON, parameters: [
            "product": "\(product.id)",
            "collection": product.collectionPermalink,
            "cognitoId": self.cognitoID]) { response in
                let success = response != nil
                if !success {
                    product.isFavorited = !favorite
                }

                completion(success)
        }
    }

    func userFavoriteProducts(completion: [Product]? -> ()) {
        favoriteProducts(self.cognitoID) { completion($0?[self.cognitoID] ?? []) }
    }

    private func favoriteProducts(cognitoID: CognitoID?, completion: [CognitoID : [Product]]? -> ()) {
        let path = cognitoID ?? ""
        FurniAPI.sharedInstance.get("favorites/\(path)") { response in
            guard let productDictionariesPerCognitoID = response as? JSONObject else {
                print("Error parsing favorite products in response: \(response)")
                completion(nil)
                return
            }

            var productsPerCognitoID: [CognitoID : [Product]] = [:]

            for (cognitoID, productsDictionary) in productDictionariesPerCognitoID {
                guard let productDictionaries = ((productsDictionary as? JSONObject)?["products"]) as? [JSONObject] else {
                    print("Error parsing favorite products in response: \(response)")
                    completion(nil)
                    return
                }

                let products = productDictionaries.map { Product(dictionary: $0, collectionPermalink: ($0["collection"] as? String) ?? "") }.sort { $0.id > $1.id }

                productsPerCognitoID[cognitoID] = products
            }

            completion(productsPerCognitoID)
        }
    }

    func uploadDigitsFriends(digitsUserIDs digitsUserIDs: [String], completion: Bool -> ()) {
        FurniAPI.sharedInstance.post("friendships", parameters: [
            "from": self.cognitoID,
            "to": digitsUserIDs
            ]) { response in
                print("\(response as! NSDictionary)")
                let success = response != nil

                completion(success)
        }
    }

    func friends(completion: [User]? -> ()) {
        FurniAPI.sharedInstance.get("friendships/\(self.cognitoID)") { response in
            guard let result = response as? JSONObject,
                let friendsDictionaries = result["friends"] as? [JSONObject] else {
                completion(nil)
                return
            }

            var users: [User] = []

            for friend in friendsDictionaries {
                let user = User()
                user.cognitoID = friend["cognitoId"] as? String
                user.digitsUserID = friend["digitsId"] as? String
                user.digitsPhoneNumber = friend["phoneNumber"] as? String

                user.populateWithLocalContact()

                users.append(user)
            }

            self.favoriteProducts(self.cognitoID) { productsByCognitoID in
                guard let productsByCognitoID = productsByCognitoID else {
                    completion(nil)
                    return
                }

                for user in users {
                    let favoriteProducts = user.cognitoID.flatMap { productsByCognitoID[$0] } ?? []
                    user.favorites = favoriteProducts
                }

                completion(users)
            }
        }
    }
}