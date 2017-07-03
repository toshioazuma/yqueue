//
//  MerchantEditMenuOptionTVC.swift
//  YQueue
//
//  Created by Aleksandr on 25/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantEditMenuOptionTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var priceTextField: UITextField! {
        didSet {
            priceTextField.reactive.continuousTextValues
                .filter { !($0?.hasPrefix("$ "))! }
                .observe { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    
                    if let text: String = $0.value! {
                        self.priceTextField.text = "$ ".appending(text.priceDigits)
                    }
            }
        }
    }
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: MerchantEditMenuOptionVM = model as! MerchantEditMenuOptionVM? {
                nameTextField.reactive.text <~ model.name.signal
                    .take(until: modelChangeSignal!)
                    .take(first: 1)
                model.price.signal
                    .take(until: modelChangeSignal!)
                    .take(first: 1)
                    .observeValues { [weak self] in
                        guard let `self` = self else {
                            return
                        }
                        
                        self.priceTextField.text = $0 == 0 ? "" : String($0)
                        if $0 != 0 {
                            // skip adding dollar sign for new options
                            OperationQueue.main.addOperation {
                                // dispatch async because otherwise we will receive deadlock
                                self.priceTextField.sendActions(for: .editingChanged)
                            }
                        }
                }
                
                model.name <~ nameTextField.reactive.continuousTextValues
                    .map { $0 as String! }.take(until: modelChangeSignal!)
                model.price <~ priceTextField.reactive.continuousTextValues
                    .map {
                        var price = 0.0
                        if let text: String = $0, text.hasPrefix("$ ") {
                            if let priceValue: Double = Double(text.replacingOccurrences(of: "$ ", with: "")) {
                                price = priceValue
                            }
                        }
                        
                        return price
                    }.take(until: modelChangeSignal!)
            }
        }
    }
}
