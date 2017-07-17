//
//  MerchantEditMenuDataTVC.swift
//  YQueue
//
//  Created by Toshio on 25/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantEditMenuDataTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var specialOfferTextView: UITextView!
    @IBOutlet weak var numberTextField: UITextField! {
        didSet {
            numberTextField.setCharactersLimit(6)
        }
    }
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var categoryButton: UIButton! {
        didSet {
            categoryButton.reactive.trigger(for: .touchUpInside).observeValues { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                _ = MerchantEditMenuCategoryAlertVC.show(in: Storyboard.appVC!,
                                                         categoryLabel: self.categoryLabel,
                                                         observer: self.categoryObserver)
            }
        }
    }
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
    
    var categorySignal: Signal<MenuCategory, NoError>
    var categoryObserver: Observer<MenuCategory, NoError>
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: MerchantEditMenuDataVM = model as! MerchantEditMenuDataVM? {
                nameTextField.reactive.text <~ model.name.signal
                    .take(until: modelChangeSignal!)
                    .take(first: 1)
                descriptionTextView.reactive.text <~ model.descriptionText.signal
                    .take(until: modelChangeSignal!)
                    .take(first: 1)
                specialOfferTextView.reactive.text <~ model.specialOfferText.signal
                    .take(until: modelChangeSignal!)
                    .take(first: 1)
                numberTextField.reactive.text <~ model.number.signal
                    .take(until: modelChangeSignal!)
                    .take(first: 1)
                
                if model.menuItem != nil {
                    model.price.signal
                        .take(until: modelChangeSignal!)
                        .take(first: 1)
                        .observeValues { [weak self] in
                            guard let `self` = self else {
                                return
                            }
                            
                            self.priceTextField.text = String(format: "%.2f", $0)
                            OperationQueue.main.addOperation {
                                // dispatch async because otherwise we will receive deadlock
                                self.priceTextField.sendActions(for: .editingChanged)
                            }
                        }
                }
                categoryLabel.reactive.text <~ model.menuCategory.signal
                    .take(until: modelChangeSignal!)
                    .take(first: 1)
                    .map { $0 != nil ? $0?.title : "" }
                    
                model.name <~ nameTextField.reactive.continuousTextValues
                    .map { $0 as String! }.take(until: modelChangeSignal!)
                model.descriptionText <~ descriptionTextView.reactive.continuousTextValues
                    .map { $0 as String! }.take(until: modelChangeSignal!)
                model.specialOfferText <~ specialOfferTextView.reactive.continuousTextValues
                    .map { $0 as String! }.take(until: modelChangeSignal!)
                model.number <~ numberTextField.reactive.continuousTextValues
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
                model.menuCategory <~ categorySignal
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        (categorySignal, categoryObserver) = Signal<MenuCategory, NoError>.pipe()
        super.init(coder: aDecoder)
    }
}
