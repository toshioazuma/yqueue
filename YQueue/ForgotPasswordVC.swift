//
//  ForgotPasswordVC.swift
//  YQueue
//
//  Created by Toshio on 07/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result
import MBProgressHUD

class ForgotPasswordVC: BaseVC {
    
    // pre-calculated
    private static var bottomOffsetWithKeyboard: CGFloat = 80
    private static var logoHeightDefaultValue: CGFloat = 0
    
    @IBOutlet weak var logoWrapper: UIView!
    @IBOutlet weak var logoHeight: NSLayoutConstraint!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var codeTextFieldLabel: UILabel!
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var codeTextFieldSeparator: UIView!
    @IBOutlet weak var passwordTextFieldLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordTextFieldSeparator: UIView!
    @IBOutlet weak var repeatPasswordTextFieldLabel: UILabel!
    @IBOutlet weak var repeatPasswordTextField: UITextField!
    @IBOutlet weak var repeatPasswordTextFieldSeparator: UIView!
    @IBOutlet weak var requestCodeButton: UIButton!
    @IBOutlet weak var alreadyHaveACodeButton: UIButton!
    @IBOutlet weak var changePasswordButton: UIButton!
    @IBOutlet weak var resendCodeButton: UIButton!
    @IBOutlet weak var bottomOffset: NSLayoutConstraint!
    
    let form = Form()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideNavigationBar()
        addTapGestureRecognizer()
        
        #if MERCHANT
            logoImageView.image = UIImage(named: "logo_merchant")
        #endif
        
        form.add(emailTextField, validation: .email)
        
        var requestCodeDisposable: Disposable? = nil
        
        let openFullForm: () -> Void = { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            if let disposable: Disposable = requestCodeDisposable {
                disposable.dispose()
            }
            
            ForgotPasswordVC.bottomOffsetWithKeyboard = 117
            
            self.emailTextField.isEnabled = false
            
            self.codeTextFieldLabel.isHidden = false
            self.codeTextField.isHidden = false
            self.codeTextFieldSeparator.isHidden = false
            
            self.passwordTextFieldLabel.isHidden = false
            self.passwordTextField.isHidden = false
            self.passwordTextFieldSeparator.isHidden = false
            
            self.repeatPasswordTextFieldLabel.isHidden = false
            self.repeatPasswordTextField.isHidden = false
            self.repeatPasswordTextFieldSeparator.isHidden = false
            
            self.requestCodeButton.isHidden = true
            self.alreadyHaveACodeButton.isHidden = true
            
            self.changePasswordButton.isHidden = false
            self.resendCodeButton.isHidden = false
            
            self.form.add(self.codeTextField, validation: .empty)
            self.form.add(self.passwordTextField, validation: .length(value: 6))
            self.form.add(self.repeatPasswordTextField, validator: Form.Validator.equal(self.repeatPasswordTextField, to: self.passwordTextField))
            
            self.form.onSubmit(with: self.changePasswordButton).observeValues { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                Storyboard.showProgressHUD()
                
                Api.auth.restorePassword(email: $0[0], code: $0[1], password: $0[2]).observe(on: QueueScheduler.main).observe { [weak self] in
                    Storyboard.hideProgressHUD()
                    guard let `self` = self else {
                        return
                    }
                    
                    if let _ = $0.error {
                        UIAlertController.show(okAlertIn: self, withTitle: "Warning", message: "Confirmation code is wrong")
                    } else {
                        Storyboard.proceedToApp(from: self)
                    }
                }
            }
            
            self.emailTextField.sendActions(for: .editingChanged)
        }
        
        _ = form.invalidSignal?.observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            var errorMessage = ""
            if $0 == self.codeTextField {
                errorMessage = "Code shouldn't be empty"
            } else if $0 == self.passwordTextField {
                errorMessage = "New password should be at least 6 characters long"
            } else if $0 == self.repeatPasswordTextField {
                errorMessage = "Passwords do not match"
            }
            
            UIAlertController.show(okAlertIn: self,
                                   withTitle: "Warning",
                                   message: errorMessage)
        }
        
        alreadyHaveACodeButton.reactive.trigger(for: .touchUpInside).observe { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            openFullForm()
            self.emailTextField.isEnabled = true
        }
        
        requestCodeDisposable = form.onSubmit(with: requestCodeButton).observeValues { [weak self] in
            Storyboard.showProgressHUD()
            
            Api.auth.forgotPassword(email: $0[0]).observe(on: QueueScheduler.main).observe { [weak self] in
                Storyboard.hideProgressHUD()
                guard let `self` = self else {
                    return
                }
                
                if let _ = $0.error {
                    UIAlertController.show(okAlertIn: self, withTitle: "Warning", message: "Couldn't find a user with this e-mail")
                } else {
                    openFullForm()
                }
            }
        }
        _ = form.invalidSignal?.observeValues { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            UIAlertController.show(okAlertIn: self,
                                   withTitle: "Warning",
                                   message: "Invalid e-mail provided")
        }
        
        keyboardSignal.observe { [weak self] in
            guard let `self` = self else {
                return
            }
            
            let height = $0.value!
            if height == 0 {
                self.bottomOffset.constant = 0
                if ForgotPasswordVC.logoHeightDefaultValue > 0 {
                    self.logoHeight.constant = ForgotPasswordVC.logoHeightDefaultValue
                }
            } else {
                self.bottomOffset.constant = $0.value! - ForgotPasswordVC.bottomOffsetWithKeyboard
                
                self.view.layoutIfNeeded()
                if self.logoHeight.constant > 0 {
                    if self.logoWrapper.frame.size.height - 20 < self.logoHeight.constant * 1.5 {
                        ForgotPasswordVC.logoHeightDefaultValue = self.logoHeight.constant
                        self.logoHeight.constant = 0
                    } else if ForgotPasswordVC.logoHeightDefaultValue > 0 {
                        self.logoHeight.constant = ForgotPasswordVC.logoHeightDefaultValue
                    }
                }
            }
        }
    }
    
    @IBAction func cancel() {
        Storyboard.pop(self)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
