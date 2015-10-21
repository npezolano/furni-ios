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

final class SignInViewController: UIViewController {

    static let storyboardIdentifier = "SignInViewController"

    // MARK: Properties

    @IBOutlet private weak var signInDigitsButton: UIButton!

    @IBOutlet private weak var signInTwitterButton: UIButton!

    private var completion: ((success: Bool) -> ())?

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Decorate the Sign In with Digits and Twitter buttons.
        signInDigitsButton.decorateForFurni()
        signInTwitterButton.decorateForFurni()

        // Add custom images to the buttons with the proper rendering mode.
        signInDigitsButton.setImage(UIImage(named: "Digits")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        signInTwitterButton.setImage(UIImage(named: "Twitter")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
    }

    private func authenticateWithService(service: Service) {
        AccountManager.defaultAccountManager.authenticateWithService(service) { success in
            if success {
                self.dismissViewControllerAnimated(true) {
                    self.completion?(success: success)
                    self.completion = nil
                }
            }
        }
    }

    // MARK: IBActions

    @IBAction private func signInDigitsButtonTapped(sender: UIButton) {
        self.authenticateWithService(.Digits)
    }

    @IBAction private func signInTwitterButtonTapped(sender: UIButton) {
        self.authenticateWithService(.Twitter)
    }

    @IBAction private func closeButtonTapped(sender: AnyObject) {
        appDelegate.tabBarController.dismissViewControllerAnimated(true) { }
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    static func presentSignInViewController(withCompletion completion: (Bool -> ())) {
        let signInViewController = UIStoryboard.mainStoryboard.instantiateViewControllerWithIdentifier(SignInViewController.storyboardIdentifier) as! SignInViewController
        signInViewController.completion = completion

        // Create a blur effect.
        // let blurEffect = UIBlurEffect(style: .Dark)
        // let blurEffectView = UIVisualEffectView(effect: blurEffect)
        // blurEffectView.frame = UIScreen.mainScreen().bounds
        // signInViewController.view.backgroundColor = UIColor.clearColor()
        // signInViewController.view.insertSubview(blurEffectView, atIndex: 0)

        // Customize the sign in view controller presentation and transition styles.
        signInViewController.modalPresentationStyle = .OverCurrentContext
        signInViewController.modalTransitionStyle = .CrossDissolve

        // Present the sign in view controller.
        appDelegate.tabBarController.presentViewController(signInViewController, animated: true, completion: nil)
    }
}
