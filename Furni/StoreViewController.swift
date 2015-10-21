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
import Optimizely

final class StoreViewController: UIViewController, UITableViewDelegate {

    private enum StoreLayout {
        case Basic
        case Rich
    }

    // MARK: Properties

    @IBOutlet private var tableView: UITableView!

    private let tableViewSectionHeaderHeight: CGFloat = 0.1
    private let tableViewSectionFooterHeight: CGFloat = 20

    private lazy var refreshControl = UIRefreshControl()

    private let collectionTableViewDataSource = CollectionTableViewDataSource<CollectionCell>()
    private let collectionPreviewTableViewDataSource = CollectionTableViewDataSource<CollectionPreviewCell>()

    private var dataSource: UITableViewDataSource? {
        didSet {
            self.tableView.dataSource = dataSource
            self.tableView.reloadData()
        }
    }

    private var storeLayout: StoreLayout = .Basic {
        didSet {
            switch storeLayout {
            case .Basic: self.dataSource = collectionTableViewDataSource
            case .Rich: self.dataSource = collectionPreviewTableViewDataSource
            }
        }
    }

    var collections: [Collection] = [] {
        didSet {
            collectionTableViewDataSource.collections = collections
            collectionPreviewTableViewDataSource.collections = collections
            tableView.reloadData()
        }
    }

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup the refresh control.
        tableView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: Selector("fetchCollections"), forControlEvents: .ValueChanged)

        // Fetch collections from the API.
        fetchCollections()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Setup A/B testing with Optimizely to switch layout based on a code block.
        Optimizely.codeBlocksWithKey(storeLayoutCodeBlock,
            blockOne: { [weak self] in self?.storeLayout = .Basic },
            blockTwo: { [weak self] in self?.storeLayout = .Rich },
            defaultBlock: { [weak self] in self?.storeLayout = .Basic }
        )
    }

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return self.cellHeightForLayout(self.storeLayout)
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return tableViewSectionHeaderHeight
    }

    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return tableViewSectionFooterHeight
    }

    // MARK: UIStoryboardSegue Handling

    private func collectionAtIndexPath(indexPath: NSIndexPath) -> Collection {
        return self.collections[indexPath.section]
    }

    private enum Segue: String {
        case ViewCollectionBasicLayout = "ViewCollectionBasicLayoutSegue"
        case ViewCollectionRichLayout = "ViewCollectionRichLayoutSegue"
        case ViewProduct = "ViewProductSegue"
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case Segue.ViewCollectionBasicLayout.rawValue, Segue.ViewCollectionRichLayout.rawValue:
            let indexPath = tableView.indexPathForSelectedRow!
            let collection = collectionAtIndexPath(indexPath)

            let productCollectionViewController = segue.destinationViewController as! ProductCollectionViewController
            productCollectionViewController.collection = collection

            // Log Content View Event in Answers.
            Answers.logContentViewWithName(collection.name,
                contentType: "Collection",
                contentId: String(collection.id),
                customAttributes: nil
            )
        case Segue.ViewProduct.rawValue:
            // Note: this is a naive way of retrieving which product was tapped on the collection view. In a production app, this could be implemented in a more maintainable way without the use of storyboard segues.
            let cell = sender as! ProductPreviewCollectionViewCell
            let product = cell.product

            let productDetailViewController = segue.destinationViewController as! ProductDetailViewController
            productDetailViewController.product = product

            // Log Content View Event in Answers.
            Answers.logContentViewWithName(product.name,
                contentType: "Product",
                contentId: String(product.id),
                customAttributes: nil
            )
        default:
            fatalError("Unhandled Segue identifier \(segue.identifier)")
        }
    }

    private func cellHeightForLayout(layout: StoreLayout) -> CGFloat {
        switch layout {
        case .Basic:
            return view.bounds.width / 2 + 10
        case .Rich:
            return view.bounds.width / 2 + 100
        }
    }

    // MARK: API

    func fetchCollections() {
        // Fetch collections from the API.
        FurniAPI.sharedInstance.getCollectionList { collections in
            // Sort collections by most recent first and reload the table.
            self.collections = collections.sort { $0.date!.compare($1.date!) == .OrderedDescending }
            self.tableView.reloadData()

            // Stop animating the refresh control.
            self.refreshControl.endRefreshing()
        }
    }
}
