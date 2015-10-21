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

final class FriendHeaderView: UICollectionReusableView {

    // MARK: Properties

    static let reuseIdentifier = "FriendHeader"

    @IBOutlet private weak var friendImageView: UIImageView!

    @IBOutlet private weak var friendNameLabel: UILabel!

    @IBOutlet private weak var friendFavoriteCountLabel: UILabel!

    @IBOutlet weak var messageButton: UIButton!

    // MARK: IBActions

    var showMessageButton: Bool = true {
        didSet {
            self.messageButton.hidden = !showMessageButton
        }
    }

    var sendMessageCallback: (() -> ())!

    @IBAction func sendMessageButtonTapped(sender: UIButton) {
        self.sendMessageCallback()
    }

    // MARK: View Life Cycle

    override func awakeFromNib() {
        super.awakeFromNib()

        // Draw a border layer at the top and bottom.
        self.drawTopBorderWithColor(UIColor.furniBrownColor(), height: 0.5)
        self.drawTopBorderWithColor(UIColor.furniBrownColor(), height: 0.5)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Add rounded corners to the image.
        friendImageView.layer.cornerRadius = friendImageView.bounds.width / 2
        friendImageView.layer.masksToBounds = true
    }

    func configureWithUser(user: User) {
        friendNameLabel.text = user.fullName
        friendImageView.image = user.image
        friendFavoriteCountLabel.text = "\(user.favorites.count) Favorites"
    }
}
