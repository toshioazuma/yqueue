//
//  CustomerSlipTVC.swift
//  YQueue
//
//  Created by Toshio on 06/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result
import MGSwipeTableCell
import MBProgressHUD

class CustomerSlipTVC: MGSwipeTableCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameHeight: NSLayoutConstraint!
    @IBOutlet weak var optionLabel: UILabel!
    @IBOutlet weak var optionArrow: UIView!
    @IBOutlet weak var optionButton: UIButton!
    @IBOutlet weak var countLabel: UILabel! {
        didSet {
            countLabel.layer.cornerRadius = 15.0
            countLabel.layer.borderColor = UIColor(white: 188.0/255.0, alpha: 1).cgColor
            countLabel.layer.borderWidth = 0.5
        }
    }
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var addItemButton: UIButton!
    @IBOutlet weak var addItemButtonLabel: UILabel!
    @IBOutlet weak var removeItemButton: UIButton!
    @IBOutlet weak var removeItemButtonLabel: UILabel!
    
    var addRow = false {
        didSet {
            idTextField.isHidden = !addRow
            
            idLabel.isHidden = addRow
            nameLabel.isHidden = addRow
            optionLabel.isHidden = addRow
            optionArrow.isHidden = addRow
            optionButton.isHidden = addRow
            countLabel.isHidden = addRow
            priceLabel.isHidden = addRow
            totalPriceLabel.isHidden = addRow
            addItemButtonLabel.isHidden = addRow
            removeItemButtonLabel.isHidden = addRow
        }
    }
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: CustomerSlipVM = model as! CustomerSlipVM? {
                if let item: Basket.Item = model.item {
                    self.addRow = false
                    
                    self.rightButtons = [MGSwipeButton(title: "Remove",
                                                       backgroundColor: UIColor(red: 255.0/255.0,
                                                                                green: 142.0/255.0,
                                                                                blue: 120.0/255.0,
                                                                                alpha: 1),
                                                       callback: { _ in
                                                        Basket.shared.remove(item)
                                                        return true
                    })]
                    
                    idLabel.text = item.menuItem.number
                    nameLabel.text = item.menuItem.name
                    
                    optionArrow.isHidden = false
                    optionLabel.isHidden = false
                    if let option: MenuItem.Option = item.option {
                        optionLabel.text = option.name
                    } else {
                        optionLabel.text = "No option"
                        if item.menuItem.options.count == 0 {
                            optionLabel.isHidden = true
                            optionArrow.isHidden = true
                        }
                    }
                    
                    optionButton.reactive.trigger(for: .touchUpInside)
                        .take(until: modelChangeSignal!)
                        .observeValues { [weak self] in
                            guard let `self` = self else {
                                return
                            }
                            
                            if item.menuItem.options.count > 0 {
                                _ = CustomerSlipOptionAlertVC.show(in: Storyboard.appVC!,
                                                                   withOptions: item.menuItem.options,
                                                                   optionLabel: self.optionLabel,
                                                                   selectionCallback: {
                                                                    Basket.shared.change(optionFor: item, to: $0)
                                                                    model.offset.consume(-model.offset.value)
//                                    for _ in 1...item.count {
//                                        Basket.shared.add(item.menuItem, option: $0)
//                                    }
//                                    Basket.shared.remove(item)
                                }, offsetCallback: {
                                    model.offset.consume($0)
                                })
                            }
                    }
                    
                    countLabel.reactive.text <~ model.count.signal
                        .take(until: modelChangeSignal!)
                        .map { "\($0)" }
                    
                    priceLabel.reactive.text <~ model.count.signal
                        .take(until: modelChangeSignal!)
                        .map { "\($0)x$\(item.price)" }
                    
                    totalPriceLabel.reactive.text <~ model.count.signal
                        .take(until: modelChangeSignal!)
                        .map { _ in "$\(item.totalPrice)" }
                    
                    addItemButton.reactive
                        .trigger(for: .touchUpInside)
                        .take(until: modelChangeSignal!)
                        .observeValues {
                            model.count.consume(model.count.value+1)
                            Basket.shared.add(item.menuItem, option: item.option)
                    }
                    
                    removeItemButton.reactive
                        .trigger(for: .touchUpInside)
                        .take(until: modelChangeSignal!)
                        .observeValues {
                            model.count.consume(model.count.value-1)
                            Basket.shared.remove(item.menuItem, option: item.option)
                    }
                } else {
                    self.addRow = true
                    idTextField.text = ""
                    nameLabel.text = "" // trigger auto-height for no content
                    
                    idTextField.reactive.trigger(for: .editingDidEndOnExit)
                        .take(until: modelChangeSignal!)
                        .observeValues { [weak self] in
                            guard let `self` = self else {
                                return
                            }
                            Storyboard.showProgressHUD()
                            
                            Api.menuItems.byId(self.idTextField.text!, merchant: model.merchant)
                                .observe(on: QueueScheduler.main)
                                .observe { [weak self] in
                                    Storyboard.hideProgressHUD()
                                    guard let `self` = self else {
                                        return
                                    }
                                    
                                    if $0.error != nil {
                                        UIAlertController.show(okAlertIn: Storyboard.appVC!,
                                                               withTitle: "Warning",
                                                               message: "Internet connection appears to be offline")
                                        return
                                    }
                                   
                                    if let menuItem: MenuItem = $0.value! {
                                        self.idTextField.resignFirstResponder()
                                        let option: MenuItem.Option? = menuItem.options.count > 0 ? menuItem.options[0] : nil
                                        Basket.shared.add(menuItem, option: option)
                                    }
                            }
                        }
                }
            }
        }
    }
}
