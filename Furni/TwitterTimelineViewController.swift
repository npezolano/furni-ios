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
import TwitterKit

final class TwitterTimelineViewController: TWTRTimelineViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Customize the Tweet appearance to use Furni colors.
        let tweetViewAppearance = TWTRTweetView.appearance()
        tweetViewAppearance.primaryTextColor = UIColor.furniDarkGrayColor()
        tweetViewAppearance.backgroundColor = UIColor.furniBeigeColor()
        tweetViewAppearance.linkTextColor = UIColor.furniOrangeColor()

        // Data source for a collection of Tweets related to Furni and home furnishing trends.
        self.dataSource = TWTRCollectionTimelineDataSource(collectionID: "654736881075093504", APIClient: TWTRAPIClient())
    }
}
