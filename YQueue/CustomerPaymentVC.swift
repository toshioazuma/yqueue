//
//  CustomerPaymentVC.swift
//  YQueue
//
//  Created by Toshio on 05/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerPaymentVC: BaseVC {
    
    var merchant: Merchant!
    var order: Order!
    @IBOutlet weak var tableView: ModelTableView!
    
    
    deinit {
        print("paymentvc deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Payment"
        _ = addBackButton()
        
        let basket = Basket.shared
        
        var models = [ModelTableViewCellModelProtocol]()
        models.append(ModelTableViewCellModel(reuseIdentifier: "OrderListHeader", rowHeight: 44))
        
        for item in basket.items {
            models.append(CustomerPaymentRowVM.item(item))
        }
        
        models.append(CustomerPaymentRowVM.subTotal(basket: basket))
        models.append(CustomerPaymentRowVM.saving(basket: basket))
        models.append(CustomerPaymentRowVM.tax(basket: basket, merchant: merchant))
        models.append(CustomerPaymentRowVM.total(basket: basket, merchant: merchant))
        models.append(CustomerPaymentRowVM.gst(basket: basket, merchant: merchant))
        
        models.append(ModelTableViewCellModel(reuseIdentifier: "Space", rowHeight: 16))
//        models.append(ModelTableViewCellModel(reuseIdentifier: "PaymentMethodHeader", rowHeight: 41))
//        
        var paymentMethods = PaymentMethod.get()
        let paymentMethod: PaymentMethod? = paymentMethods.count > 0 ? paymentMethods[0] : nil
        models.append(CustomerPaymentMethodVM(paymentMethod: paymentMethod, tap: {
            let model = $0
            
            if model.paymentMethod != nil {
                Storyboard.openPaymentMethods(selectionCallback: {
                    model.paymentMethod = $0
                    model.modelBound()
                })
            } else {
                Storyboard.addPaymentMethod(addCallback: {
                    paymentMethods.append($0)
                    PaymentMethod.save(paymentMethods)
                    model.paymentMethod = $0
                    model.modelBound()
                })
            }
        }))
//        models.append(CustomerPaymentMethodVM(paymentMethod: nil, tap: { 
//            
//        }))
        models.append(CustomerPayVM(callback: { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.pay()
        }))
        
        tableView.headerModel = CustomerRewardsCouponsVM()
        tableView.models = models
    }
    
    func pay() {
        var paymentMethodFromModel: PaymentMethod?
        
        for model in tableView.models {
            if let paymentMethodModel: CustomerPaymentMethodVM = model as? CustomerPaymentMethodVM {
                paymentMethodFromModel = paymentMethodModel.paymentMethod
                break
            }
        }
        
        guard let paymentMethod: PaymentMethod = paymentMethodFromModel else {
            UIAlertController.show(okAlertIn: self,
                                   withTitle: "Warning",
                                   message: "You should choose payment method to proceed")
            return
        }
        
        let alert = UIAlertController(title: "Payment",
                                      message: "Enter your CVV code:",
                                      preferredStyle: .alert)
        alert.addTextField {
            $0.isSecureTextEntry = true
            $0.placeholder = "3 or 4 digits"
        }
        
        alert.addAction(UIAlertAction(title: "Pay", style: .default, handler: { [weak self] _ in
            if let `self` = self {
                self.proceed(withPaymentMethod: paymentMethod,
                                    cvv: alert.textFields![0].text!)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    func proceed(withPaymentMethod paymentMethod: PaymentMethod, cvv: String) {
        if cvv.characters.count < 3 || cvv.characters.count > 4 {
            UIAlertController.show(okAlertIn: self,
                                   withTitle: "Warning",
                                   message: "CVV must be 3 or 4 digits longs")
            return
        }
        
        Storyboard.showProgressHUD()
        Api.paymentGateway.pay(order: order, with: paymentMethod, securityCode: cvv)
            .observe(on: QueueScheduler.main)
            .observeValues { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                if let errorMessage: String = $0 {
                    Storyboard.hideProgressHUD()
                    
                    UIAlertController.show(okAlertIn: self,
                                           withTitle: "Warning",
                                           message: errorMessage)
                } else {
                    Api.orders.pay(self.order)
                        .observe(on: QueueScheduler.main)
                        .observeValues { [weak self] in
                            Storyboard.hideProgressHUD()
                            guard let `self` = self else {
                                return
                            }
                            
                            if $0 == false {
                                UIAlertController.show(okAlertIn: self,
                                                       withTitle: "Warning",
                                                       message: "Couldn't pay an order. Please try again later.")
                            } else {
                                Storyboard.openReceipt(for: self.merchant, with: self.order, paymentMethod: paymentMethod)
                            }
                    }
                }
            }
    }
}
