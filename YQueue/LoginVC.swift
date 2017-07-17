//
//  SignInVC.swift
//  YQueue
//
//  Created by Toshio on 03/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result
import MBProgressHUD

class LoginVC: BaseVC {
    
    // pre-calculated
    private static let bottomOffsetWithNoKeyboard: CGFloat = 29
    private static let bottomOffsetWithKeyboard: CGFloat = 133
    private static var logoHeightDefaultValue: CGFloat = 0
    
    // views
    @IBOutlet weak var logoWrapper: UIView!
    @IBOutlet weak var logoHeight: NSLayoutConstraint!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var facebookIcon: UIImageView!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var bottomOffset: NSLayoutConstraint!
    
    let form = Form()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideNavigationBar()
        addTapGestureRecognizer()
        
        if let username: String = Api.auth.username, let password: String = Api.auth.password {
            Storyboard.showProgressHUD()
            
            Api.auth.signIn(username: username, password: password).observe(on: QueueScheduler.main).observe { [weak self] in
                Storyboard.hideProgressHUD()
                guard let `self` = self else {
                    return
                }
                
                guard let _ = $0.error else {
                    Storyboard.proceedToApp(from: self)
                    return
                }
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        
        #if MERCHANT
            logoImageView.image = UIImage(named: "logo_merchant")
            facebookButton.isHidden = true
            facebookIcon.isHidden = true
            signUpButton.isHidden = true
        #endif
        
        form.add(emailTextField, validation: .email)
        form.add(passwordTextField, validation: .length(value: 6))
        form.onSubmit(with: loginButton).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            Storyboard.showProgressHUD()
            
            let email = $0[0]
            Api.auth.signIn(username: email, password: $0[1]).observe(on: QueueScheduler.main).observe { [weak self] in
                Storyboard.hideProgressHUD()
                guard let `self` = self else {
                    return
                }
                
                if let error = $0.error {
                    if error == .failed {
                        UIAlertController.show(okAlertIn: self,
                                               withTitle: "Warning",
                                               message: "Wrong e-mail or password")
                    } else {
                        #if CUSTOMER
                            Storyboard.confirmRegistration(from: self,
                                                           forUserWithEmail: email)
                        #else
                            UIAlertController.show(okAlertIn: self,
                                                   withTitle: "Warning",
                                                   message: "Wrong e-mail or password")
                        #endif
                    }
                } else {
                    Storyboard.proceedToApp(from: self)
                }
            }
        }
        _ = form.invalidSignal?.observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            var errorMessage = ""
            if $0 == self.emailTextField {
                errorMessage = "Invalid e-mail provided"
            } else if $0 == self.passwordTextField {
                errorMessage = "Password should be at least 6 digits long"
            }
            
            UIAlertController.show(okAlertIn: self,
                                   withTitle: "Warning",
                                   message: errorMessage)
        }
        
        #if CUSTOMER
        facebookButton.reactive.trigger(for: .touchUpInside).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
                
            Storyboard.showProgressHUD()
            
            Api.auth.authFacebook(from: self).observe(on: QueueScheduler.main).observe { [weak self] in
                Storyboard.hideProgressHUD()
                guard let `self` = self else {
                    return
                }
                
                print("auth facebook error = \($0.error)")
                if let _ = $0.error {
                    UIAlertController.show(okAlertIn: self, withTitle: "Warning", message: "Couldn't auth you with Facebook, please try again later")
                } else {
                    Storyboard.proceedToApp(from: self)
                }
            }
        }
        #endif
        
        keyboardSignal.observe { [weak self] in
            guard let `self` = self else {
                return
            }
            
            let height = $0.value!
            if height == 0 {
                self.bottomOffset.constant = LoginVC.bottomOffsetWithNoKeyboard
                if LoginVC.logoHeightDefaultValue > 0 {
                    self.logoHeight.constant = LoginVC.logoHeightDefaultValue
                }
            } else {
                self.bottomOffset.constant = $0.value! - LoginVC.bottomOffsetWithKeyboard
                
                self.view.layoutIfNeeded()
                if self.logoHeight.constant > 0 {
                    if self.logoWrapper.frame.size.height - 20 < self.logoHeight.constant * 1.5 {
                        LoginVC.logoHeightDefaultValue = self.logoHeight.constant
                        self.logoHeight.constant = 0
                    } else if LoginVC.logoHeightDefaultValue > 0 {
                        self.logoHeight.constant = LoginVC.logoHeightDefaultValue
                    }
                }
            }
        }
    }
    
    @IBAction func forgotPasswordButtonClicked() {
        Storyboard.recoverPassword(from: self)
    }
    
    @IBAction func signUpButtonClicked() {
        #if CUSTOMER
        Storyboard.signUp(from: self)
        #endif
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
