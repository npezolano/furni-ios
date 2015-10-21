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
import AlamofireImage
import MessageUI
import ContactsUI

class FavoritesCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, MFMessageComposeViewControllerDelegate {

    // MARK: Properties

    var friends: [User] = [] {
        didSet {
            self.collectionView!.reloadData()
        }
    }

    static let emptyFooterReusableID = "EmptyFooter"

    var refreshControl: UIRefreshControl?

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup the refresh control.
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: "fetchFavoriteProducts", forControlEvents: .ValueChanged)
        collectionView!.addSubview(refreshControl!)

        collectionView!.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: FavoritesCollectionViewController.emptyFooterReusableID)

        collectionView!.delegate = self

        // Fetch friends and favorite products from the API.
        fetchFavoriteProducts()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        AccountManager.defaultAccountManager.user?.populateWithLocalContact()
        self.fetchFavoriteProducts()
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return friends.count
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return friends[section].favorites.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCellWithReuseIdentifier(ProductCell.reuseIdentifier, forIndexPath: indexPath)
    }

    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        let cell = cell as! ProductCell

        // Find the corresponding product.
        let product = friends[indexPath.section].favorites[indexPath.row]

        // Configure the cell with the product.
        cell.configureWithProduct(product)
    }

    private func shouldDisplayFindFriendsFooter() -> Bool {
        // return AccountManager.defaultAccountManager.digitsIdentity != nil && friends.count < 2
        // Note: For the demo, always suggest to find friends the first time.
        return !AccountManager.defaultAccountManager.hasUploadedContacts
    }

    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        switch kind {
            case UICollectionElementKindSectionHeader:
                // Dequeue the friend header view.
                let friendHeaderView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: FriendHeaderView.reuseIdentifier, forIndexPath: indexPath) as! FriendHeaderView

                // Find the corresponding user.
                let user = friends[indexPath.section]

                // Show or hide the message button.
                let friendIsMe = user === AccountManager.defaultAccountManager.user
                friendHeaderView.showMessageButton = !friendIsMe
                friendHeaderView.sendMessageCallback = { [unowned self] in
                    self.sendMessageToFriend(user)
                }

                // Configure the view with the user.
                friendHeaderView.configureWithUser(user)

                // Return the header view.
                return friendHeaderView
            case UICollectionElementKindSectionFooter:
                let isLastSection = indexPath.section == numberOfSectionsInCollectionView(collectionView) - 1
                if isLastSection && shouldDisplayFindFriendsFooter() {
                    // Dequeue the find friends footer view.
                    let friendFooterView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionFooter, withReuseIdentifier: FriendFooterView.reuseIdentifier, forIndexPath: indexPath) as! FriendFooterView

                    // Handle the button callback.
                    friendFooterView.findFriendsCallback = { [unowned self] in
                        self.uploadContactsToSearchForFriends()
                    }

                    // Return the footer view.
                    return friendFooterView
                } else {
                    // Return an empty footer view.
                    let footer = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionFooter, withReuseIdentifier: FavoritesCollectionViewController.emptyFooterReusableID, forIndexPath: indexPath)
                    footer.frame = CGRectZero
                    return footer
                }
            default: ()
        }

        return UICollectionReusableView()
    }

    // MARK: UICollectionViewDelegateFlowLayout

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let spacing = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).sectionInset.left
        let width = (view.bounds.width - 3 * spacing) / 2
        return CGSize(width: width, height: width + 50)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let isFindFriendsSection = (section == numberOfSectionsInCollectionView(collectionView) - 1) && shouldDisplayFindFriendsFooter()

        let height: CGFloat
        if isFindFriendsSection {
            height = FriendFooterView.height
        } else {
            height = 0
        }

        return CGSize(width: self.view.bounds.size.width, height: height)
    }

    // MARK: UIStoryboardSegue Handling

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let productCell = sender as! ProductCell

        // Pass the selected product to the detail view controller.
        let productDetailViewController = segue.destinationViewController as! ProductDetailViewController
        productDetailViewController.product = productCell.product
    }

    private func uploadContactsToSearchForFriends() {
        AccountManager.defaultAccountManager.uploadContacts() { _ in
            self.fetchFavoriteProducts()
        }
    }

    private func displayErrorAlertWithTitle(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .Alert
        )
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }

    // MARK: MFMessageComposeViewControllerDelegate

    private func sendMessageToFriend(friend: User) {
        guard MFMessageComposeViewController.canSendText() else {
            displayErrorAlertWithTitle("Cannot Send Message.", message: "Sorry, your device is not able to send messages.")
            return
        }
        guard let phoneNumber = friend.digitsPhoneNumber else {
            displayErrorAlertWithTitle("Cannot Send Message.", message: "This contact does not have a phone number available.")
            return
        }

        // Create a message composer view controller and present it.
        let messageComposerViewController = MFMessageComposeViewController()
        messageComposerViewController.messageComposeDelegate = self
        messageComposerViewController.recipients = [phoneNumber]
        messageComposerViewController.body = "Hey, just exploring the products you favorited on Furni!"
        presentViewController(messageComposerViewController, animated: true, completion: nil)
    }

    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: API

    // We need to upload the contacts before this.
    func fetchFavoriteProducts() {
        self.refreshControl!.beginRefreshing()
        AccountManager.defaultAccountManager.authenticatedAPI?.friends() { friends in
            // Add the logged in user as the first account to display.
            let loggedUser = AccountManager.defaultAccountManager.user!
            self.friends = [loggedUser]

            // For this demo app, only append friends once the Address Book has been uploaded.
            // if CNContactStore.authorizationStatusForEntityType(.Contacts) == .Authorized {
            if AccountManager.defaultAccountManager.hasUploadedContacts {
                self.friends.appendContentsOf(friends ?? [])
            }

            self.refreshControl!.endRefreshing()
        }
    }
}
