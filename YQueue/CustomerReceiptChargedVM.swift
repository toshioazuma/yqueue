//
//  CustomerReceiptChargedVM.swift
//  YQueue
//
//  Created by Aleksandr on 07/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerReceiptChargedVM: NSObject, ModelTableViewCellModelProtocol {
    
    var charged = MutableProperty(0.0)
    var icon: MutableProperty<UIImage>
    var text = MutableProperty("")
    
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = "Charged"
    var rowHeight: CGFloat? = 56
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    init(basket: Basket, merchant: Merchant, paymentMethod: PaymentMethod) {
        let total = basket.items.map{ $0.totalPrice }.reduce(0, +)
        let tax = total * merchant.tax / 100.0
        let grandTotal = round((total+tax) * 100.0) / 100.0
        
        icon = MutableProperty<UIImage>(UIImage(named: paymentMethod.type.lowercased() == "visa" ? "pay_visa" : "pay_mc")!)
        charged.consume(grandTotal)
        text.consume(paymentMethod.cardNumber)
        
        super.init()
    }
    
    func modelBound() {
    }
}
