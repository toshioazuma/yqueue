//
//  ConfirmRegistrationVC.swift
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

class ConfirmRegistrationVC: BaseVC {
    
    // pre-calculated
    private static let bottomOffsetWithKeyboard: CGFloat = 117
    private static var logoHeightDefaultValue: CGFloat = 0
    
    // views
    @IBOutlet weak var logoWrapper: UIView!
    @IBOutlet weak var logoHeight: NSLayoutConstraint!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var bottomOffset: NSLayoutConstraint!
    
    let confirmForm = Form()
    var resendForm = Form()
    var email: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideNavigationBar()
        addTapGestureRecognizer()
        
        confirmForm.add(emailTextField, validation: .email)
        confirmForm.add(codeTextField, validation: .empty)
        confirmForm.onSubmit(with: confirmButton).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            Storyboard.showProgressHUD()
            print("confirm form valid")
            Api.auth.confirmRegistration(email: $0[0], code: $0[1]).observe(on: QueueScheduler.main).observe { [weak self] in
                Storyboard.hideProgressHUD()
                guard let `self` = self else {
                    return
                }
                
                if let _ = $0.error {
                    UIAlertController.show(okAlertIn: self, withTitle: "Warning", message: "Invalid code provided")
                } else {
                    Storyboard.proceedToApp(from: self)
                }
            }
        }
        _ = confirmForm.invalidSignal?.observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            var errorMessage = ""
            if $0 == self.emailTextField {
                errorMessage = "Invalid e-mail provided"
            } else if $0 == self.codeTextField {
                errorMessage = "Code shouldn't be empty"
            }
            
            UIAlertController.show(okAlertIn: self,
                                   withTitle: "Warning",
                                   message: errorMessage)
        }
        
        resendForm.add(emailTextField, validation: .email)
        resendForm.onSubmit(with: resendButton).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            Storyboard.showProgressHUD()
            
            print("resend form valid")
            Api.auth.resendConfirmationCode(email: $0[0]).observe(on: QueueScheduler.main).observe { [weak self] in
                Storyboard.hideProgressHUD()
                guard let `self` = self else {
                    return
                }
                
                if let _ = $0.error {
                    UIAlertController.show(okAlertIn: self, withTitle: "Warning", message: "Invalid e-mail provided")
                } else {
                    self.emailTextField.isEnabled = false
                }
            }
        }
        _ = resendForm.invalidSignal?.observeValues { [weak self] _ in
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
                if ConfirmRegistrationVC.logoHeightDefaultValue > 0 {
                    self.logoHeight.constant = ConfirmRegistrationVC.logoHeightDefaultValue
                }
            } else {
                self.bottomOffset.constant = $0.value! - ConfirmRegistrationVC.bottomOffsetWithKeyboard
                
                self.view.layoutIfNeeded()
                if self.logoHeight.constant > 0 {
                    if self.logoWrapper.frame.size.height - 20 < self.logoHeight.constant * 1.5 {
                        ConfirmRegistrationVC.logoHeightDefaultValue = self.logoHeight.constant
                        self.logoHeight.constant = 0
                    } else if ConfirmRegistrationVC.logoHeightDefaultValue > 0 {
                        self.logoHeight.constant = ConfirmRegistrationVC.logoHeightDefaultValue
                    }
                }
            }
        }
        
        if let providedEmail = email {
            emailTextField.text = providedEmail
            emailTextField.sendActions(for: UIControlEvents.editingChanged) // let RAC validation start
            emailTextField.isEnabled = false
        }
    }
    
    @IBAction func cancelButtonClicked() {
        Storyboard.pop(self)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
