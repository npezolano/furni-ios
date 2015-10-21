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

final class ProductCollectionViewController: UICollectionViewController {

    // MARK: Properties

    var collection: Collection!

    private var headerImageView: UIImageView?

    private var refreshControl: UIRefreshControl!

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Customize the navigation bar.
        let shareButton = UIBarButtonItem(title: "Share", style: .Plain, target: self, action: "shareButtonTapped")
        navigationItem.rightBarButtonItem = shareButton
        navigationItem.title = collection.name

        // Setup the refresh control.
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "fetchCollectionProducts", forControlEvents: .ValueChanged)
        collectionView!.addSubview(refreshControl)
        collectionView!.sendSubviewToBack(refreshControl)

        // Fetch products from the API.
        fetchCollectionProducts()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Tie this selected collection to any crashes in Crashlytics.
        Crashlytics.sharedInstance().setObjectValue(collection.id, forKey: "Collection")
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collection.products.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ProductCell.reuseIdentifier, forIndexPath: indexPath) as! ProductCell

        // Find the corresponding product.
        let product = collection.products[indexPath.row]

        // Configure the cell with the product.
        cell.configureWithProduct(product)

        // Return the product cell.
        return cell
    }

    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        guard kind == UICollectionElementKindSectionHeader else { return UICollectionReusableView() }

        // Dequeue the collection header view.
        let collectionHeaderView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "CollectionHeader", forIndexPath: indexPath)

        // Add the image subview by loading the banner from the network.
        let size = CGSize(width: collectionHeaderView.bounds.width, height: collectionHeaderView.bounds.height)
        headerImageView = UIImageView(frame: collectionHeaderView.frame)
        headerImageView!.af_setImageWithURL(
            collection.largeImageURL,
            placeholderImage: UIImage(named: "Placeholder"),
            filter: AspectScaledToFillSizeFilter(size: size),
            imageTransition: .CrossDissolve(0.6)
        )
        collectionHeaderView.addSubview(headerImageView!)

        return collectionHeaderView
    }

    // MARK: UICollectionViewDelegate

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let spacing = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).sectionInset.left
        let width = (view.bounds.width - 3 * spacing) / 2
        return CGSize(width: width, height: width + 50)
    }

    // MARK: UIStoryboardSegue Handling

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let cell = sender as! ProductCell

        let productDetailViewController = segue.destinationViewController as! ProductDetailViewController
        productDetailViewController.product = cell.product
    }

    // MARK: Actions

    @objc private func shareButtonTapped() {
        // Use the TwitterKit to create a Tweet composer.
        let composer = TWTRComposer()

        // Prepare the Tweet with an image and a URL.
        composer.setText("Check out this amazing collection of products I found on @furni!")
        composer.setImage(headerImageView?.image!)
        composer.setURL(collection?.collectionURL)

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

    // MARK: API

    private func fetchCollectionProducts() {
        // Fetch products from the API.
        FurniAPI.sharedInstance.getCollection(collection.permalink) { collection in
            // Save and reload the table.
            self.collectionView!.reloadData()

            // Stop animating the refresh control.
            self.refreshControl!.endRefreshing()
        }
    }
}
