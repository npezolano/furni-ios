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

import UIKit

final class CartFooterCell: UITableViewCell {

    static let reuseIdentifier = "CartFooterCell"

    // MARK: Properties

    @IBOutlet private weak var totalItemsLabel: UILabel!

    @IBOutlet private weak var subtotalPriceLabel: UILabel!

    @IBOutlet private weak var shippingPriceLabel: UILabel!

    @IBOutlet private weak var totalPriceLabel: UILabel!

    @IBOutlet private weak var payButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        payButton.decorateForFurni()

        self.contentView.drawTopBorderWithColor(UIColor.furniBrownColor(), height: 0.5)
    }

    func configureWithCart(cart: Cart) {
        // Assign the labels.
        totalItemsLabel.text = "\(cart.productCount()) Items"
        subtotalPriceLabel.text = cart.subtotalAmount().asCurrency
        shippingPriceLabel.text = cart.shippingAmount().asCurrency
        totalPriceLabel.text = cart.totalAmount().asCurrency
    }
}
