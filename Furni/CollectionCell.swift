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
import AlamofireImage

final class CollectionCell: UITableViewCell, CollectionTableViewCellType {

    static let reuseIdentifier = "CollectionCell"

    // MARK: Properties

    @IBOutlet private weak var taglineLabel: UILabel!

    @IBOutlet private weak var artworkImageView: UIImageView!

    // MARK: View Life Cycle

    func configureWithCollection(collection: Collection) {
        // Assign the collection name and tagline.
        taglineLabel.text = collection.tagline

        // Load the image from the network and give it the correct aspect ratio.
        let size = CGSize(width: self.bounds.width, height: self.bounds.width * 9/20)
        artworkImageView.af_setImageWithURL(
            collection.imageURL,
            placeholderImage: UIImage(named: "Placeholder"),
            filter: AspectScaledToFillSizeFilter(size: size),
            imageTransition: .CrossDissolve(0.6)
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        artworkImageView.af_cancelImageRequest()
        artworkImageView.layer.removeAllAnimations()
        artworkImageView.image = nil
    }
}
