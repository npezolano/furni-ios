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
import Crashlytics

final class Cart {
    static let sharedInstance = Cart()

    static let cartUpdatedNotificationName = "xyz.furni.cart.updated.notification"

    var items: [CartItem] = [] {
        didSet {
            postCartUpdatedNotification()
        }
    }

    init() {
    }

    init(items: [CartItem]) {
        self.items = items
    }

    func productCount() -> Int {
        var count = 0
        for item in items {
            count += item.quantity
        }
        return count
    }

    func subtotalAmount() -> Float {
        return items.map { $0.price }.reduce(0, combine: +)
    }

    func shippingAmount() -> Float {
        return 0
    }

    func totalAmount() -> Float {
        return subtotalAmount() + shippingAmount()
    }

    func addProduct(product: Product) {
        // Check if the product is already part of the cart.
        let existingCartItem = items.filter { $0.product.id == product.id }.first

        if let existingCartItem = existingCartItem {
            if existingCartItem.quantity < 10 {
                existingCartItem.quantity += 1
            }
        } else {
            items.append(CartItem(product: product))
        }

        postCartUpdatedNotification()

        // Log Cart Event in Answers.
        Answers.logAddToCartWithPrice(NSDecimalNumber(float: product.price),
            currency: "USD",
            itemName: product.name,
            itemType: "Furni",
            itemId: String(product.id),
            customAttributes: nil
        )
    }

    func removeProduct(product: Product) {
        items = items.filter { $0.product.id != product.id }
    }

    func isEmpty() -> Bool {
        return productCount() == 0
    }

    func reset() {
        items = []
    }

    private func postCartUpdatedNotification() {
        NSNotificationCenter.defaultCenter().postNotificationName(Cart.cartUpdatedNotificationName, object: self)
    }
}
