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

class Collection {
    let id: Int
    let permalink: String
    let name: String
    let tagline: String
    let description: String
    let collectionURL: NSURL
    let imageURL: NSURL
    let largeImageURL: NSURL
    let date: NSDate?
    var products: [Product] = []

    init(id: Int, permalink: String, name: String, tagline: String, description: String, collectionURL: NSURL, imageURL: NSURL, largeImageURL: NSURL) {
        self.id = id
        self.permalink = permalink
        self.name = name
        self.tagline = tagline
        self.description = description
        self.collectionURL = collectionURL
        self.imageURL = imageURL
        self.largeImageURL = largeImageURL
        self.date = NSDate()
    }

    init(dictionary: [String : AnyObject]) {
        // Note: This is a naive implementation of JSON parsing.
        // In a production Swift app, we recommend using a library such as Decodable: https://github.com/Anviking/Decodable

        id = dictionary["id"] as! Int
        permalink = dictionary["permalink"] as! String
        name = dictionary["name"] as! String
        tagline = dictionary["tagline"] as! String
        description = dictionary["description"] as! String
        collectionURL = NSURL(string: (dictionary["url"] as! String!))!

        let imageURLComponents = NSURLComponents(string: dictionary["home_page_image_url"] as! String)!
        imageURLComponents.scheme = "https"
        imageURL = imageURLComponents.URL!

        let largeImageURLComponents = NSURLComponents(string: dictionary["image_url"] as! String)!
        largeImageURLComponents.scheme = "https"
        largeImageURL = largeImageURLComponents.URL!

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dictionary["sale_starts"] as! String
        date = dateFormatter.dateFromString(dateString)!
    }
}
