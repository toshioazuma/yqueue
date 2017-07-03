//
//  SignUpVC.swift
//  YQueue
//
//  Created by Aleksandr on 04/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result
import MBProgressHUD

class SignupVC: BaseVC {
    
    // pre-calculated
    private static let bottomOffsetWithKeyboard: CGFloat = 117
    private static var logoHeightDefaultValue: CGFloat = 0
    
    @IBOutlet weak var logoWrapper: UIView!
    @IBOutlet weak var logoHeight: NSLayoutConstraint!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var repeatPasswordTextField: UITextField!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var bottomOffset: NSLayoutConstraint!
    
    let form = Form()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideNavigationBar()
        addTapGestureRecognizer()
        
        form.add(nameTextField, validation: .empty)
        form.add(emailTextField, validation: .email)
        form.add(passwordTextField, validation: .length(value: 6))
        form.add(repeatPasswordTextField, validator: Form.Validator.equal(repeatPasswordTextField, to: passwordTextField))
        form.onSubmit(with: signupButton).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            Storyboard.showProgressHUD()
            
            let email = $0[1]
            Api.auth.signUp(email: email, password: $0[2], name: $0[0]).observe(on: QueueScheduler.main).observe { [weak self] in
                Storyboard.hideProgressHUD()
                guard let `self` = self else {
                    return
                }
                
                if let error = $0.error {
                    if error == .failed {
                        UIAlertController.show(okAlertIn: self, withTitle: "Warning", message: "E-mail already registered")
                    } else {
                        Storyboard.confirmRegistration(from: self, forUserWithEmail: email)
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
            if $0 == self.nameTextField {
                errorMessage = "Name shouldn't be empty"
            } else if $0 == self.emailTextField {
                errorMessage = "Invalid e-mail provided"
            } else if $0 == self.passwordTextField {
                errorMessage = "Password should be at least 6 digits long"
            } else if $0 == self.repeatPasswordTextField {
                errorMessage = "Passwords do not match'"
            }
            
            UIAlertController.show(okAlertIn: self,
                                   withTitle: "Warning",
                                   message: errorMessage)
        }
        
        facebookButton.reactive.trigger(for: .touchUpInside).observe { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            Storyboard.showProgressHUD()
            
            Api.auth.authFacebook(from: self).observe(on: QueueScheduler.main).observe { [weak self] in
                Storyboard.hideProgressHUD()
                guard let `self` = self else {
                    return
                }
                
                if let _ = $0.error {
                    UIAlertController.show(okAlertIn: self, withTitle: "Warning", message: "Couldn't auth you with Facebook, please try again later")
                } else {
                    Storyboard.proceedToApp(from: self)
                }
            }
        }
        
        keyboardSignal.observe { [weak self] in
            guard let `self` = self else {
                return
            }
            
            let height = $0.value!
            if height == 0 {
                self.bottomOffset.constant = 0
                if SignupVC.logoHeightDefaultValue > 0 {
                    self.logoHeight.constant = SignupVC.logoHeightDefaultValue
                }
            } else {
                self.bottomOffset.constant = $0.value! - SignupVC.bottomOffsetWithKeyboard
                
                self.view.layoutIfNeeded()
                if self.logoHeight.constant > 0 {
                    if self.logoWrapper.frame.size.height - 20 < self.logoHeight.constant * 1.5 {
                        SignupVC.logoHeightDefaultValue = self.logoHeight.constant
                        self.logoHeight.constant = 0
                    } else if SignupVC.logoHeightDefaultValue > 0 {
                        self.logoHeight.constant = SignupVC.logoHeightDefaultValue
                    }
                }
            }
        }
    }
    
    @IBAction func haveAnAccountButtonClicked() {
        Storyboard.pop(self)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
