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
import Fabric
import Crashlytics
import TwitterKit
import DigitsKit
import Optimizely
import Stripe
import AWSCognito

let storeLayoutCodeBlock = OptimizelyCodeBlocksKey("StoreLayout", blockNames: ["BasicStoreLayout", "RichStoreLayout"])

let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate {

    var window: UIWindow?

    var tabBarController: UITabBarController {
        return self.window!.rootViewController as! UITabBarController
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Developers: Welcome! Get started with Fabric.app.
        let welcome = "Welcome to Furni! Please onboard with the Fabric Mac app. Check the instructions in the README file."
        precondition(NSBundle.mainBundle().objectForInfoDictionaryKey("Fabric") != nil, welcome)

        // Register Fabric Kits.
        Fabric.with([Crashlytics.self, Twitter.self, Digits.self, Optimizely.self])

        // Setup Optimizely.
        Optimizely.startOptimizelyWithAPIToken("Your Optimizely API Token", launchOptions:launchOptions)
        Optimizely.preregisterBlockKey(storeLayoutCodeBlock)

        // Setup the account manager.
        AccountManager.setUpDefaultAccountManager(AccountManager())

        // Customize the tab bar.
        UITabBar.appearance().tintColor = UIColor.furniOrangeColor()

        // Customize the navigation bar.
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), forBarMetrics: .Default)

        self.tabBarController.delegate = self

        return true
    }

    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        return Optimizely.handleOpenURL(url)
    }

    // MARK: UITabBarControllerDelegate

    private static let viewControllerClassesThatRequireUserSession: [AnyObject.Type] = [FavoritesCollectionViewController.self, CartViewController.self, AccountViewController.self]

    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        guard !AccountManager.defaultAccountManager.isUserLoggedIn else {
            return true
        }

        let visibleController: UIViewController

        if let navigationController = viewController as? UINavigationController {
            visibleController = navigationController.topViewController ?? viewController
        } else {
            visibleController = viewController
        }

        let shouldPresentSignInScreen = AppDelegate.viewControllerClassesThatRequireUserSession.contains { $0 == visibleController.dynamicType }

        if shouldPresentSignInScreen {
            SignInViewController.presentSignInViewController() { success in
                if success {
                    self.tabBarController.selectedViewController = viewController
                }
            }

            return false
        }

        return true
    }
}
