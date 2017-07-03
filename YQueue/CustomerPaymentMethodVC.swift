//
//  CustomerPaymentMethodVC.swift
//  YQueue
//
//  Created by Aleksandr on 07/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerPaymentMethodVC: BaseVC {

    var deleteCallback: (() -> Void)!
    var paymentMethod: PaymentMethod!
    
    @IBOutlet weak var cardTypeLabel: UILabel!
    @IBOutlet weak var cardNumberLabel: UILabel!
    @IBOutlet weak var cvvAndExpLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        _ = addBackButton()
        addTapGestureRecognizer()
        
        cardTypeLabel.text = "Payment Method: \(paymentMethod.type)"
        cardNumberLabel.text = "Card Number: \(paymentMethod.cardNumber)"
        cvvAndExpLabel.text = "Exp. Date: xx/xx - CVV: xxx"
        
        deleteButton.reactive.trigger(for: .touchUpInside).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.deleteCallback()
            Storyboard.pop()
        }
    }
}
