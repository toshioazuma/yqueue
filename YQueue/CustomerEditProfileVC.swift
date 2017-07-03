//
//  CustomerEditProfileVC.swift
//  YQueue
//
//  Created by Aleksandr on 06/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerEditProfileVC: BaseVC {
    
    @IBOutlet weak var email: CustomerChangePasswordInput!
    @IBOutlet weak var name: CustomerChangePasswordInput!
    @IBOutlet weak var phone: CustomerChangePasswordInput!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var bottomOffset: NSLayoutConstraint!
    
    let form = Form()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Edit Profile"
        _ = addBackButton()
        addTapGestureRecognizer()
        
        let isFacebookUser = (Api.auth.username?.hasPrefix("fb_"))!
        
        email.textField.text = Api.auth.email
        email.textField.isEnabled = isFacebookUser
        name.textField.text = Api.auth.name ?? ""
        phone.textField.text = Api.auth.phone
        
        form.add(email.textField, validation: isFacebookUser ? .emailOptional : .email)
        form.add(name.textField, validation: .empty)
        form.add(phone.textField, validation: .none)
        _ = form.onSubmit(with: saveButton)
        
        email.checkmark.reactive.isHidden <~ (form.wrapper(for: email.textField)?.invalid.signal)!
        name.checkmark.reactive.isHidden <~ (form.wrapper(for: name.textField)?.invalid.signal)!
        phone.checkmark.reactive.isHidden <~ (form.wrapper(for: phone.textField)?.invalid.signal)!
        
        form.onSubmit(with: saveButton).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            Storyboard.showProgressHUD()
            
            Api.auth.editProfile(email: $0[0], name: $0[1], phone: $0[2])
                .observe(on: QueueScheduler.main)
                .observeValues { [weak self] in
                    Storyboard.hideProgressHUD()
                    guard let `self` = self else {
                        return
                    }
                    
                    if $0 {
                    } else {
                        UIAlertController.show(okAlertIn: self,
                                               withTitle: "Warning",
                                               message: "Couldn't change your profile details")
                    }
                }
        }
        
        form.invalidSignal?.observeValues {
            print("failed to submit form because of text field \($0.text)")
        }
    
        for textField in [email.textField,
                          name.textField,
                          phone.textField] {
                            textField?.sendActions(for: .editingChanged)
        }
        
        keyboardSignal.observe { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.bottomOffset.constant = $0.value!
        }
    }
}
