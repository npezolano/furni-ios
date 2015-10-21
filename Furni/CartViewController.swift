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
import Stripe
import Alamofire

private struct PaymentConfiguration {
    // Stripe Key: https://dashboard.stripe.com/account/apikeys
    let stripePublishableKey: String

    // Backend Charge URL: https://github.com/stripe/example-ios-backend
    let backendChargeURLString: String

    // Apple Pay: https://stripe.com/docs/mobile/apple-pay
    let appleMerchantID: String
}

final class CartViewController: UITableViewController, PKPaymentAuthorizationViewControllerDelegate {

    // MARK: Properties

    private let cart = Cart.sharedInstance

    private let paymentConfiguration: PaymentConfiguration? = PaymentConfiguration(
        stripePublishableKey: "Your Stripe Publishable Key",
        backendChargeURLString: "Your Backend Charge URL",
        appleMerchantID: "merchant.xyz.furni"
    )

    override func awakeFromNib() {
        super.awakeFromNib()

        // Listen to notifications about the cart being updated.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("cartUpdatedNotificationReceived"), name: Cart.cartUpdatedNotificationName, object: self.cart)
    }

    // Order price in cents.
    private var orderPriceCents: Float = 0

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Put a label as the background view to display when the cart is empty.
        let emptyCartLabel = UILabel()
        emptyCartLabel.numberOfLines = 0
        emptyCartLabel.textAlignment = .Center
        emptyCartLabel.textColor = UIColor.furniDarkGrayColor()
        emptyCartLabel.font = UIFont.systemFontOfSize(CGFloat(20))
        emptyCartLabel.text = "Your cart is empty.\nGo add some nice products! 😉"
        tableView.backgroundView = emptyCartLabel
        tableView.backgroundView?.hidden = true
        tableView.backgroundView?.alpha = 0
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.tableView.reloadData()
        toggleEmptyCartLabel()
    }


    // MARK: IBActions

    @IBAction func beginPayment(sender: AnyObject) {
        // Check if a payment configuration is available.
        guard let paymentConfiguration = self.paymentConfiguration else {
            self.displayLackOfPaymentConfigurationAlert()
            return
        }

        // Only returns nil if we are on iOS < 8.
        let paymentRequest = Stripe.paymentRequestWithMerchantIdentifier(paymentConfiguration.appleMerchantID)!

        // Check if Apple Pay is available.
        guard Stripe.canSubmitPaymentRequest(paymentRequest) else {
            print("Apple Pay is not available.")
            return
        }

        // Update the shipping contact using the user postal address.
        if let user = AccountManager.defaultAccountManager.user {
            user.populateWithLocalContact()
            
            let contact = PKContact()
            let name = NSPersonNameComponents()
            name.givenName = user.fullName
            contact.name = name

            contact.phoneNumber = user.digitsPhoneNumber.map(CNPhoneNumber.init)
            contact.postalAddress = user.postalAddress
            paymentRequest.shippingContact = contact
        }

        // Setup the payment request.
        paymentRequest.requiredShippingAddressFields = .PostalAddress
        paymentRequest.requiredBillingAddressFields = .Email
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Subtotal", amount: NSDecimalNumber(float: cart.subtotalAmount())),
            PKPaymentSummaryItem(label: "Shipping", amount: NSDecimalNumber(float: cart.shippingAmount())),
            PKPaymentSummaryItem(label: "Furni", amount: NSDecimalNumber(float: cart.totalAmount()))
        ]

        // Log Start Checkout Event in Answers.
        Answers.logStartCheckoutWithPrice(NSDecimalNumber(float: cart.totalAmount()),
            currency: "USD",
            itemCount: cart.productCount(),
            customAttributes: nil
        )

        // Setup and present the payment view controller.
        let paymentAuthViewController = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest)
        paymentAuthViewController.delegate = self
        presentViewController(paymentAuthViewController, animated: true, completion: nil)
    }

    private func displayLackOfPaymentConfigurationAlert() {
        let alert = UIAlertController(
            title: "You need to set your Stripe publishable key.",
            message: "You can find your publishable key at https://dashboard.stripe.com/account/apikeys",
            preferredStyle: .Alert
        )
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }

    // MARK: PKPaymentAuthorizationViewControllerDelegate

    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: ((PKPaymentAuthorizationStatus) -> Void)) {

        // Note: We pretend the payment is successful for demo purposes.
        completion(.Success)

        // Navigation to the order successful view controller.
        self.performSegueWithIdentifier("OrderSuccessfulSegue", sender: self)

        // Reset the cart.
        self.cart.reset()

        // Setup the Stripe API client to create a token from the payment.
        let apiClient = STPAPIClient(publishableKey: paymentConfiguration!.stripePublishableKey)
        apiClient.createTokenWithPayment(payment, completion: { token, error in
            guard let token = token else {
                completion(.Failure)
                return
            }
            self.createBackendChargeWithToken(token, completion: { result, error in
                guard result == .Success else {
                    completion(.Failure)
                    return
                }
                // Log Purchase Custom Events in Answers.
                for item in self.cart.items {
                    Answers.logPurchaseWithPrice(NSDecimalNumber(float: item.product.price),
                        currency: "USD",
                        success: true,
                        itemName: item.product.name,
                        itemType: "Furni",
                        itemId: String(item.product.id),
                        customAttributes: ["Quantity": item.quantity]
                    )
                }
            })
        })
    }

    func paymentAuthorizationViewControllerDidFinish(controller: PKPaymentAuthorizationViewController) {
        dismissViewControllerAnimated(true) { }
    }

    // MARK: Stripe

    func createBackendChargeWithToken(token: STPToken, completion: STPTokenSubmissionHandler) {
        guard let backendChargeURLString = paymentConfiguration?.backendChargeURLString where !backendChargeURLString.isEmpty else {
            completion(.Failure, NSError(domain: StripeDomain, code: 50, userInfo: [NSLocalizedDescriptionKey: "You created a token! Its value is \(token.tokenId). Now configure your backend to accept this token and complete a charge."]))
            return
        }

        let url = NSURL(string: backendChargeURLString)!.URLByAppendingPathComponent("charge")
        let chargeParams: [String: AnyObject] = ["stripeToken": token.tokenId, "amount": orderPriceCents]

        // Create the POST request to the backend to process the charge.
        request(.POST, url, parameters: chargeParams).responseJSON(completionHandler: { request, response, result in
            if response?.statusCode == 200 {
                completion(.Success, nil)
            } else {
                completion(.Failure, nil)
            }
        })
    }

    // MARK: UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return cart.isEmpty() ? 0 : 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of items in the cart.
        return cart.items.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CartItemCell.reuseIdentifier, forIndexPath: indexPath) as! CartItemCell

        // Find the corresponding cart item.
        let cartItem = cart.items[indexPath.row]

        // Keep a weak reference on the table view.
        cell.cartItemQuantityChangedCallback = { [unowned self] in
            self.refreshCartDisplay()
            self.tableView.reloadData()
        }

        // Configure the cell with the cart item.
        cell.configureWithCartItem(cartItem)

        // Return the cart item cell.
        return cell
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        guard editingStyle == .Delete else { return }

        // Remove this item from the cart and refresh the table view.
        cart.items.removeAtIndex(indexPath.row)

        // Either delete some rows within the section (leaving at least one) or the entire section.
        if cart.items.count > 0 {
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else {
            tableView.deleteSections(NSIndexSet(index: indexPath.section), withRowAnimation: .Fade)
        }

        // Log Custom Event in Answers.
        Answers.logCustomEventWithName("Edited Cart", customAttributes: nil)
    }

    // MARK: UITableViewDelegate

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }

    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = tableView.dequeueReusableCellWithIdentifier(CartFooterCell.reuseIdentifier) as! CartFooterCell

        // Configure the footer with the cart.
        footerView.configureWithCart(cart)

        // Return the footer view.
        return footerView.contentView
    }

    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let tableViewHeight = UIScreen.mainScreen().bounds.height - tableView.frame.origin.y - tabBarController!.tabBar.bounds.height
        return max(150, tableViewHeight - CGFloat(80 * cart.items.count))
    }

    // MARK: Utilities

    @objc private func cartUpdatedNotificationReceived() {
        // Update the price of the cart in cents.
        orderPriceCents = cart.totalAmount() * 100.0

        // Refresh the cart display.
        self.refreshCartDisplay()
    }

    private func refreshCartDisplay() {
        let cartTabBarItem = self.parentViewController!.tabBarItem

        // Update the tab bar badge.
        let productCount = cart.productCount()
        cartTabBarItem!.badgeValue = productCount > 0 ? String(productCount) : nil

        // Update the tab bar icon.
        if productCount > 0 {
            cartTabBarItem?.image = UIImage(named: "Cart-Full")
            cartTabBarItem?.selectedImage = UIImage(named: "Cart-Full-Selected")
        } else {
            cartTabBarItem?.image = UIImage(named: "Cart")
            cartTabBarItem?.selectedImage = UIImage(named: "Cart-Selected")
        }

        // Toggle the empty cart label if needed.
        toggleEmptyCartLabel()
    }

    private func toggleEmptyCartLabel() {
        if cart.isEmpty() {
            UIView.animateWithDuration(0.15) {
                self.tableView.backgroundView!.hidden = false
                self.tableView.backgroundView!.alpha = 1
            }
        } else {
            UIView.animateWithDuration(0.15,
                animations: {
                    self.tableView.backgroundView!.alpha = 0
                },
                completion: { finished in
                    self.tableView.backgroundView!.hidden = true
                }
            )
        }
    }
}
