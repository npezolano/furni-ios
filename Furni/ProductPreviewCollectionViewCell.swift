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

final class ProductPreviewCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier = "ProductPreviewCollectionViewCell"

    // MARK: Properties

    var product: Product!

    @IBOutlet private var imageView: UIImageView!

    // MARK: View Life Cycle

    override func awakeFromNib() {
        // Draw a border around the cell.
        layer.masksToBounds = true
        layer.borderColor = UIColor.furniBrownColor().CGColor
        layer.borderWidth = 0.5
        layer.cornerRadius = 3
    }

    func configureWithProduct(product: Product) {
        self.product = product
        
        // Load the image from the network and give it the correct aspect ratio.
        let size = CGSize(width: self.bounds.width, height: self.bounds.height)
        imageView.af_setImageWithURL(
            product.imageURL,
            placeholderImage: UIImage(named: "Placeholder"),
            filter: AspectScaledToFitSizeFilter(size: size),
            imageTransition: .CrossDissolve(0.6)
        )
    }
}
