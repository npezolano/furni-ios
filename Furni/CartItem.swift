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

class CartItem {

    var product: Product
    var quantity: Int = 0

    init(product: Product) {
        self.product = product
        self.quantity = 1
    }

    init(product: Product, quantity: Int) {
        self.product = product
        self.quantity = quantity
    }

    var price: Float {
        return self.product.price * Float(self.quantity)
    }

}
