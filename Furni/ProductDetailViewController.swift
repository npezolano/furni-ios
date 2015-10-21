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
import Crashlytics
import TwitterKit
import AlamofireImage

final class ProductDetailViewController: UIViewController {

    // MARK: Properties

    var product: Product!

    @IBOutlet private weak var nameLabel: UILabel!

    @IBOutlet private weak var priceLabel: UILabel!

    @IBOutlet private weak var retailPriceLabel: UILabel!

    @IBOutlet private weak var percentOffLabel: UILabel!

    @IBOutlet private weak var imageView: UIImageView!

    @IBOutlet private weak var descriptionLabel: UILabel!

    @IBOutlet private weak var addToCartButton: UIButton!

    @IBOutlet private weak var favoriteButton: UIButton!

    private var favorited: Bool = false {
        didSet {
            favoriteButton.setImage(UIImage.favoriteImageForFavoritedState(favorited), forState: .Normal)
        }
    }

    // MARK: IBActions

    @IBAction private func favoriteButtonTapped(sender: AnyObject) {
        let favorite = !self.favorited
        self.favorited = favorite

        let product = self.product
        AccountManager.defaultAccountManager.authenticatedAPI?.favoriteProduct(favorite, product: self.product) { success in
            guard product === self.product else { return }

            if !success {
                self.favorited = !favorite
            }
        }
    }

    @IBAction private func addToCartButtonTapped(sender: AnyObject) {
        Cart.sharedInstance.addProduct(product)
    }

    @objc private func shareButtonTapped() {
        // Use the TwitterKit to create a Tweet composer.
        let composer = TWTRComposer()

        // Prepare the Tweet with an image and a URL.
        composer.setText("Check out this amazing product I found on @furni!")
        composer.setImage(imageView.image)
        composer.setURL(product.productURL)

        // Present the composer to the user.
        composer.showFromViewController(self) { result in
            if result == .Done {
                // Log Custom Event in Answers.
                Answers.logCustomEventWithName("Tweet Completed", customAttributes: nil)
            } else if result == .Cancelled {
                // Log Custom Event in Answers.
                Answers.logCustomEventWithName("Tweet Cancelled", customAttributes: nil)
            }
        }
    }

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Customize the navigation bar.
        let shareButton = UIBarButtonItem(title: "Share", style: .Plain, target: self, action: "shareButtonTapped")
        navigationItem.rightBarButtonItem = shareButton
        navigationItem.title = "Details"

        // Add product name and description labels.
        nameLabel.text = product.name
        descriptionLabel.text = product.description

        // Add the current and retail prices with their currency.
        priceLabel.text = product.price.asCurrency
        retailPriceLabel.text = nil
        percentOffLabel.text = nil
        if product.price < product.retailPrice && product.percentOff > 0 {
            let retailPriceString = String(product.retailPrice.asCurrency)
            let attributedRetailPrice = NSMutableAttributedString(string: retailPriceString)
            attributedRetailPrice.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: NSMakeRange(0, retailPriceString.characters.count))
            attributedRetailPrice.addAttribute(NSStrikethroughColorAttributeName, value: UIColor.furniDarkGrayColor(), range: NSMakeRange(0, retailPriceString.characters.count))
            retailPriceLabel.attributedText = attributedRetailPrice
            percentOffLabel.text = "-\(product.percentOff)%"
        }

        // Load the image from the network and give it the correct aspect ratio.
        let size = CGSize(width: imageView.bounds.width, height: imageView.bounds.height)
        imageView.af_setImageWithURL(
            product.imageURL,
            placeholderImage: UIImage(named: "Placeholder"),
            filter: AspectScaledToFitSizeFilter(size: size),
            imageTransition: .CrossDissolve(0.6)
        )

        // Set the icon if the product has been favorited.
        self.favorited = product.isFavorited

        // Draw a border around the product image and put a white background.
        imageView.layer.masksToBounds = false
        imageView.layer.backgroundColor = UIColor.whiteColor().CGColor
        imageView.layer.borderColor = UIColor.furniBrownColor().CGColor
        imageView.layer.borderWidth = 0.5
        imageView.layer.cornerRadius = 3

        // Decorate the button.
        addToCartButton.decorateForFurni()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Tie this selected product to any crashes in Crashlytics.
        Crashlytics.sharedInstance().setObjectValue(product.id, forKey: "Product")

        // Log Content View Event in Answers.
        Answers.logContentViewWithName(product.name,
            contentType: "Product",
            contentId: String(product.id),
            customAttributes: nil
        )
    }
}
