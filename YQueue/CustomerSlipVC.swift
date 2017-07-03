//
//  CustomerSlipVC.swift
//  YQueue
//
//  Created by Aleksandr on 05/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerSlipVC: BaseVC {
    
    var merchant: Merchant!
    
    @IBOutlet weak var headerHeight: NSLayoutConstraint!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var tableNoTextField: UITextField!
    @IBOutlet weak var tableView: ModelTableView!
    @IBOutlet weak var bottomOffset: NSLayoutConstraint!
    @IBOutlet weak var grandTotalLabel: UILabel!
    @IBOutlet weak var placeOrderButton: UIButton!
    
    
    deinit {
        print("slipvc deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Storyboard.openSlipTutorial() // if wasn't displayed
        
        _ = addBackButton()
        addTapGestureRecognizer()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 69
        
        if !Storyboard.dineIn! {
            headerHeight.constant = 0
            title = "Order Details"
        } else {
            title = merchant?.title
        }
        
        placeOrderButton.roundCorners()
        
        placeOrderButton.reactive.trigger(for: .touchUpInside).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            var errorString: String?
            if Storyboard.dineIn! && self.tableNoTextField.textWithoutPrefix("Table ").characters.count == 0 {
                errorString = "Table number shouldn't be empty"
            } else if self.tableView.models.filter({ ($0 as! CustomerSlipVM).item != nil }).count == 0 {
                errorString = "Your order shouldn't be empty"
            }
            
            if let errorString: String = errorString {
                UIAlertController.show(okAlertIn: self,
                                       withTitle: "Warning",
                                       message: errorString)
            } else {
                let order: Order = Order()
                order.merchant = self.merchant
                order.type = Storyboard.dineIn! ? .dineIn : .takeAway
                order.dateTime = Date()
                order.basket = Basket.shared
                order.prepareForSave()
                
                if Storyboard.dineIn! {
                    order.tableNumber = self.tableNoTextField.textWithoutPrefix("Table ")
                } else {
                    order.tableNumber = AWS.emptyString
                }
                
                Storyboard.showProgressHUD()
                Api.orders.place(order).observe(on: QueueScheduler.main).observeValues { [weak self] in
                    Storyboard.hideProgressHUD()
                    guard let `self` = self else {
                        return
                    }
                    
                    if $0 == false {
                        UIAlertController.show(okAlertIn: self,
                                               withTitle: "Warning",
                                               message: "Couldn't place an order. Please try again later.")
                    } else {
                        Storyboard.openPayment(for: self.merchant, with: order)
                    }
                }
            }
        }
        
        tableNoTextField.resignFirstResponderOnReturnButton()
        tableNoTextField.setPrefix("Table ", limit: 5)
//        tableNoTextField.reactive.continuousTextValues
//            .filter {
//                !($0?.hasPrefix("Table "))! ||
//                    ($0?.replacingOccurrences(of: "Table ", with: "").characters.count)! > 5
//            }
//            .observe {
//                var text = $0.value!!
//                if text.hasPrefix("Table ") {
//                    text = text.replacingOccurrences(of: "Table ", with: "")
//                } else if "Table ".hasPrefix(text) {
//                    text = ""
//                }
//                self.tableNoTextField.text = "Table \(text.limit(5))"
//            }
        
        update(items: Basket.shared.items)
        Basket.shared.signal.observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.update(items: $0)
        }
        
        keyboardSignal.observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            if $0 == 0 || self.tableNoTextField.isFirstResponder {
                self.bottomOffset.constant = 0
            } else {
                self.bottomOffset.constant = $0 - 70.0
            }
        }
    }
    
    func update(items: [Basket.Item]) {
        var grandTotal = 0.0
        var models = [CustomerSlipVM]()
        
        for item in items {
            grandTotal += item.totalPrice
            models.append(CustomerSlipVM(item: item, offsetCallback: { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                var offset = self.tableView.contentOffset
                offset.y += $0
                self.tableView.contentOffset = offset
            }))
        }
        
        models.append(CustomerSlipVM(merchant: merchant))
        
        grandTotalLabel.text = "$".appending(grandTotal.format(precision: 2, ignorePrecisionIfRounded: true))
        tableView.models = models
    }
    
    @IBAction func menuButtonClicked() {
        Storyboard.openMenu(for: merchant)
    }
}
