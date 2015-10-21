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

final class FriendFooterView: UICollectionReusableView {

    // MARK: Properties

    static let reuseIdentifier = "FindFriendsFooter"

    static let height: CGFloat = 200

    @IBOutlet private weak var findFriendsButton: UIButton!

    // MARK: IBActions

    var findFriendsCallback: (() -> ())!

    @IBAction private func findFriendsButtonTapped() {
        self.findFriendsCallback()
    }

    // MARK: View Life Cycle

    override func awakeFromNib() {
        super.awakeFromNib()

        // Decorate the button.
        self.findFriendsButton.decorateForFurni()

        // Add a Digits custom image to the button with the proper rendering mode.
        findFriendsButton.setImage(UIImage(named: "Digits")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)

        // Draw a border layer at the top.
        self.drawTopBorderWithColor(UIColor.furniBrownColor(), height: 0.5)
    }
}
