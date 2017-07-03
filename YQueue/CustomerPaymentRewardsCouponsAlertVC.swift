//
//  CustomerPaymentRewardsCouponsAlertVC.swift
//  YQueue
//
//  Created by Aleksandr on 12/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit

class CustomerPaymentRewardsCouponsAlertVC: AlertVC {
    
    @IBOutlet weak var backgroundButton: UIButton!
    @IBOutlet weak var tableView: ModelTableView!
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var redeemButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundButton.reactive.trigger(for: .touchUpInside).observeValues {
            self.dismiss(animated: true)
        }
        
        redeemButton.reactive.trigger(for: .touchUpInside).observeValues {
            self.dismiss(animated: true)
        }
        
        let codes = ["MEAL5","MEAL10","MEAL15","CAPUFREE","MEAL5","MEAL10","MEAL15","CAPUFREE"]
        let details = ["You are eligible to earn 5% OFF in any meal",
                       "You are eligible to earn 10% OFF in any meal",
                       "You are eligible to earn 15% OFF in any meal",
                       "You are eligible to earn 1 Free Cappuccino",
                       "You are eligible to earn 5% OFF in any meal",
                       "You are eligible to earn 10% OFF in any meal",
                       "You are eligible to earn 15% OFF in any meal",
                       "You are eligible to earn 1 Free Cappuccino"]
        
        var models = Array<CustomerPaymentRewardsCouponsAlertVM>()
        for (code, details) in zip(codes, details) {
            models.append(CustomerPaymentRewardsCouponsAlertVM(code: code, details: details, tap: { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                self.dismiss(animated: true)
            }))
        }
        tableView.models = models
    }
    
    static func show(in vc: UIViewController) -> CustomerPaymentRewardsCouponsAlertVC {
        let alert = Storyboard.paymentRewardsCouponsAlert()
        alert.modalPresentationStyle = .overCurrentContext
        print("show CustomerPaymentRewardsCouponsAlertVC")
        alert.show(in: vc, animated: true)
        
        return alert
    }
}
