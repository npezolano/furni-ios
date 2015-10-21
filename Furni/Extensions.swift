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

import Foundation
import UIKit
import DigitsKit

extension UIColor {
    class func furniOrangeColor() -> UIColor {
        return UIColor(red: 1, green: 127/255, blue: 0, alpha: 1.0)
    }

    class func furniBeigeColor() -> UIColor {
        return UIColor(red: 248/255, green: 248/255, blue: 246/255, alpha: 1.0)
    }

    class func furniBrownColor() -> UIColor {
        return UIColor(red: 183/255, green: 179/255, blue: 163/255, alpha: 1.0)
    }

    class func furniDarkGrayColor() -> UIColor {
        return UIColor(red: 42/255, green: 48/255, blue: 51/255, alpha: 1.0)
    }
}

extension String {
    // Remove some occurrences of characters in a string.
    func stringByRemovingOccurrencesOfCharacters(chars: String) -> String {
        let cs = characters.filter {
            chars.characters.indexOf($0) == nil
        }

        return String(cs)
    }
}

extension Float {
    // Format a price with currency based on the device locale.
    var asCurrency: String {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        formatter.locale = NSLocale.currentLocale()
        return formatter.stringFromNumber(self)!
    }
}

extension UIButton {
    // Decorate a Furni button.
    func decorateForFurni() {
        self.layer.masksToBounds = false
        self.layer.cornerRadius = 6
    }
}

extension UIView {
    // Draw a border at the top of a view.
    func drawTopBorderWithColor(color: UIColor, height: CGFloat) {
        let topBorder = CALayer()
        topBorder.backgroundColor = color.CGColor
        topBorder.frame = CGRectMake(0, 0, self.bounds.width, height)
        self.layer.addSublayer(topBorder)
    }
}

extension UIStoryboard {
    static var mainStoryboard: UIStoryboard {
        return UIStoryboard(name: "Main", bundle: nil)
    }
}

extension UIImage {
    static func favoriteImageForFavoritedState(favorited: Bool) -> UIImage {
        let imageName: String

        if favorited {
            imageName = "Favorite-Selected"
        } else {
            imageName = "Favorite"
        }

        return UIImage(named: imageName)!
    }
}

extension DGTAppearance {
    static var furniAppearance: DGTAppearance {
        let appearance = DGTAppearance()
        appearance.accentColor = UIColor.furniOrangeColor()
        appearance.backgroundColor = UIColor.furniDarkGrayColor()
        appearance.logoImage = UIImage(named: "Logo")

        return appearance
    }
}