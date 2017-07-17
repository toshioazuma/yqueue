//
//  CustomerPaymentMethodVM.swift
//  YQueue
//
//  Created by Toshio on 07/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerPaymentMethodVM: NSObject, ModelTableViewCellModelProtocol {
    
    private let newIcon = UIImage(named: "pay_new_method")!
    var icon: MutableProperty<UIImage>
    
    var text = MutableProperty("")
    
    private let cardTextColor = UIColor(white: 32.0/255.0, alpha: 1)
    private let newTextColor = UIColor(red: 50.0/255.0, green: 209.0/255.0, blue: 125.0/255.0, alpha: 1)
    var textColor: MutableProperty<UIColor>
    
    private let cardArrowImage = UIImage(named: "menu_arrow")!
    private let newArrowImage = UIImage(named: "menu_arrow_green")!
    var arrowImage: MutableProperty<UIImage>
    
    var paymentMethod: PaymentMethod?
    var tapSignal: Signal<Void, NoError>
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = "PaymentMethod"
    var rowHeight: CGFloat? = 76
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    init(paymentMethod: PaymentMethod?, tap: @escaping (CustomerPaymentMethodVM) -> Void) {
        self.paymentMethod = paymentMethod
        
        textColor = MutableProperty(newTextColor)
        arrowImage = MutableProperty(newArrowImage)
        icon = MutableProperty(newIcon)
        
        let (tapSignal, tapObserver) = Signal<Void, NoError>.pipe()
        self.tapSignal = tapSignal
        self.tapObserver = tapObserver
        
        super.init()
        
        tapSignal.observe { [weak self] _ in
            if let `self` = self {
                tap(self)
            }
        }
    }
    
    func modelBound() {
        if let paymentMethod: PaymentMethod = paymentMethod {
            icon.consume(UIImage(named: paymentMethod.type.lowercased() == "visa" ? "pay_visa" : "pay_mc")!)
            text.consume(paymentMethod.cardNumber)
            textColor.consume(cardTextColor)
            arrowImage.consume(cardArrowImage)
        } else {
            icon.consume(newIcon)
            text.consume("Add new payment method")
            textColor.consume(newTextColor)
            arrowImage.consume(newArrowImage)
        }
    }
}
