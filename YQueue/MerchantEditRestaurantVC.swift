//
//  MerchantEditRestaurantVC.swift
//  YQueue
//
//  Created by Toshio on 22/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result
import MBProgressHUD

class MerchantEditRestaurantVC: BaseVC {

    @IBOutlet weak var restaurantTitle: MerchantChangePasswordInput!
    @IBOutlet weak var workingFrom: MerchantChangePasswordInput!
    @IBOutlet weak var workingTo: MerchantChangePasswordInput!
    @IBOutlet weak var gst: MerchantChangePasswordInput!
    @IBOutlet weak var tax: MerchantChangePasswordInput!
    @IBOutlet weak var takeAwayAvailableCheckbox: MerchantEditRestaurantCheckbox!
    @IBOutlet weak var dineInAvailableCheckbox: MerchantEditRestaurantCheckbox!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var bottomOffset: NSLayoutConstraint!
    
    let form = Form()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Edit Restaurant"
        _ = addBackButton()
        addTapGestureRecognizer()
        
        let merchant: Merchant = Api.auth.merchantUser.merchant
        restaurantTitle.textField.text = merchant.title
        workingFrom.textField.text = merchant.workingFrom.workingHoursAndMinutes
        workingTo.textField.text = merchant.workingTo.workingHoursAndMinutes
        gst.textField.text = merchant.gst.format(precision: 2, ignorePrecisionIfRounded: true)
        tax.textField.text = merchant.tax.format(precision: 2, ignorePrecisionIfRounded: true)
        
        takeAwayAvailableCheckbox.selected.consume(merchant.isTakeAwayAvailable)
        dineInAvailableCheckbox.selected.consume(merchant.isDineInAvailable)
        
        let workingHoursValidator = { (text: String?) -> Bool in
            print("validating working hours \(text)")
            if !(text?.contains(":"))! {
                return false
            }
            
            let hoursString: String = (text?.components(separatedBy: ":")[0])!
            if hoursString != hoursString.onlyDigits || hoursString.characters.count != 2 {
                return false
            }
            
            let minutesString: String = (text?.components(separatedBy: ":")[1])!
            if minutesString != minutesString.onlyDigits || minutesString.characters.count != 2 {
                return false
            }
            
            let hours: Int = Int(hoursString)!
            if hours < 0 || hours > 24 {
                return false
            }
            
            let minutes: Int = Int(minutesString)!
            if minutes < 0 || minutes > 59 {
                return false
            }
            
            return true
        }
        
        let percentValidator = { (text: String?) -> Bool in
            if let text: String = text,
                let value: Double = Double(text) {
                return value >= 0.0
            }
            
            return false
        }
        
        form.add(restaurantTitle.textField, validation: .empty)
        form.add(workingFrom.textField,
                 validator: Form.Validator.callback(textField: workingFrom.textField,
                                                    callback: workingHoursValidator))
        form.add(workingTo.textField,
                 validator: Form.Validator.callback(textField: workingTo.textField,
                                                    callback: workingHoursValidator))
        form.add(gst.textField,
                 validator: Form.Validator.callback(textField: gst.textField,
                                                    callback: percentValidator))
        form.add(tax.textField,
                 validator: Form.Validator.callback(textField: tax.textField,
                                                    callback: percentValidator))
        
        restaurantTitle.checkmark.reactive.isHidden <~ (form.wrapper(for: restaurantTitle.textField)?.invalid.signal)!
        workingFrom.checkmark.reactive.isHidden <~ (form.wrapper(for: workingFrom.textField)?.invalid.signal)!
        workingTo.checkmark.reactive.isHidden <~ (form.wrapper(for: workingTo.textField)?.invalid.signal)!
        gst.checkmark.reactive.isHidden <~ (form.wrapper(for: gst.textField)?.invalid.signal)!
        tax.checkmark.reactive.isHidden <~ (form.wrapper(for: tax.textField)?.invalid.signal)!
        
        form.onSubmit(with: saveButton).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            Storyboard.showProgressHUD()
            
            Api.merchants.editRestaurant(title: $0[0],
                                         workingFrom: $0[1].workingTime,
                                         workingTo: $0[2].workingTime,
                                         gst: Double($0[3])!,
                                         tax: Double($0[4])!,
                                         takeAwayAvailable: self.takeAwayAvailableCheckbox.selected.value,
                                         dineInAvailable: self.dineInAvailableCheckbox.selected.value)
                .observe(on: QueueScheduler.main)
                .observe { [weak self] in
                    Storyboard.hideProgressHUD()
                    guard let `self` = self else {
                        return
                    }
                    
                    if !$0.value! {
                        UIAlertController.show(okAlertIn: self,
                                               withTitle: "Warning",
                                               message: "Couldn't change restaurant details")
                    }
                }
        }
        
        for textField in [restaurantTitle.textField,
                          workingFrom.textField,
                          workingTo.textField,
                          gst.textField, tax.textField] {
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
