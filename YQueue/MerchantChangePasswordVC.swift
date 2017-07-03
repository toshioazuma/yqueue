//
//  MerchantChangePasswordVC.swift
//  YQueue
//
//  Created by Aleksandr on 22/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result
import MBProgressHUD

class MerchantChangePasswordVC: BaseVC {

    @IBOutlet weak var currentPassword: MerchantChangePasswordInput!
    @IBOutlet weak var newPassword: MerchantChangePasswordInput!
    @IBOutlet weak var repeatNewPassword: MerchantChangePasswordInput!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var bottomOffset: NSLayoutConstraint!
    
    let form = Form()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Change Password"
        _ = addBackButton()
        addTapGestureRecognizer()
        
        form.add(currentPassword.textField, validation: .equal(value: Api.auth.password!))
        form.add(newPassword.textField, validation: .length(value: 6))
        form.add(repeatNewPassword.textField, validator: Form.Validator.equal(newPassword.textField, to: repeatNewPassword.textField))
        
        currentPassword.checkmark.reactive.isHidden <~ (form.wrapper(for: currentPassword.textField)?.invalid.signal)!
        newPassword.checkmark.reactive.isHidden <~ (form.wrapper(for: newPassword.textField)?.invalid.signal)!
        repeatNewPassword.checkmark.reactive.isHidden <~ (form.wrapper(for: repeatNewPassword.textField)?.invalid.signal)!

        form.onSubmit(with: saveButton).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            Storyboard.showProgressHUD()
            
            Api.auth.changePassword(from: $0[0],
                                    to: $0[1])
                .observe(on: QueueScheduler.main).observe { [weak self] in
                Storyboard.showProgressHUD()
                guard let `self` = self else {
                    return
                }
                
                if let error = $0.error, error == .failed {
                    UIAlertController.show(okAlertIn: self, withTitle: "Warning", message: "Couldn't change your password")
                } else {
                    self.currentPassword.clear()
                    self.newPassword.clear()
                    self.repeatNewPassword.clear()
                }
            }
        }
        
        keyboardSignal.observe { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.bottomOffset.constant = $0.value!
        }
    }
}
