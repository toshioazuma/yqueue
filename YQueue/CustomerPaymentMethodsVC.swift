//
//  CustomerPaymentMethods.swift
//  YQueue
//
//  Created by Toshio on 06/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerPaymentMethodsVC: BaseVC {
    
    var selectionCallback: ((PaymentMethod) -> Void)?
    
    @IBOutlet weak var tableView: ModelTableView!
    private var paymentMethods = [PaymentMethod]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Payment Methods"
        _ = addBackButton()

        apply(paymentMethods: PaymentMethod.get())
//        PaymentMethod.load().observe(on: QueueScheduler.main).observeValues { [weak self] in
//            guard let `self` = self else {
//                return
//            }
//            
//            self.apply(paymentMethods: $0)
//        }
    }
    
    func show(actionsFor paymentMethod: PaymentMethod) {
        let alert = UIAlertController(title: nil,
                                      message: "Choose action:",
                                      preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            self.delete(paymentMethod: paymentMethod)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    func apply(paymentMethods: [PaymentMethod]) {
        self.paymentMethods = paymentMethods
        
        var models = [CustomerPaymentMethodVM]()
        for paymentMethod in paymentMethods { print("payment method token: \(paymentMethod.token)")
            models.append(CustomerPaymentMethodVM(paymentMethod: paymentMethod, tap: { [weak self] _ in
                guard let `self` = self else {
                    return
                }
                
                if self.selectionCallback != nil {
                    self.selectionCallback!(paymentMethod)
                    Storyboard.pop()
                } else {
                    self.show(actionsFor: paymentMethod)
                }
                
//                Storyboard.showPaymentMethod(paymentMethod, deleteCallback: { [weak self] in
//                    guard let `self` = self else {
//                        return
//                    }
//                    
//                    self.delete(paymentMethod: paymentMethod)
//                })
            }))
        }
        
        models.append(CustomerPaymentMethodVM(paymentMethod: nil, tap: { _ in
            Storyboard.addPaymentMethod(addCallback: { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                self.add(paymentMethod: $0)
                if self.selectionCallback != nil {
                    self.selectionCallback!($0)
                    Storyboard.pop()
                }
            })
        }))
        
        tableView.models = models
    }
    
    func add(paymentMethod: PaymentMethod) {
        paymentMethods.append(paymentMethod)
        PaymentMethod.save(paymentMethods)
        apply(paymentMethods: paymentMethods)
    }
    
    func delete(paymentMethod: PaymentMethod) {
        Storyboard.showProgressHUD()
        Api.paymentGateway.delete(tokenFor: paymentMethod)
            .observe(on: QueueScheduler.main)
            .observeValues { [weak self] in
                Storyboard.hideProgressHUD()
                
                if let `self` = self {
                    if $0 {
                        self.paymentMethods = self.paymentMethods.filter { $0 != paymentMethod }
                        PaymentMethod.save(self.paymentMethods)
                        self.apply(paymentMethods: self.paymentMethods)
                    } else {
                        UIAlertController.show(okAlertIn: self,
                                               withTitle: "Warning",
                                               message: "Couldn't delete your payment method")
                    }
                }
            }
    }
}
