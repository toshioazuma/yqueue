//
//  CustomerOrderHistoryItemTVC.swift
//  YQueue
//
//  Created by Aleksandr on 15/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerOrderHistoryItemTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var optionLabel: UILabel?
    @IBOutlet weak var priceLabel: UILabel!
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: CustomerOrderHistoryItemVM = model as! CustomerOrderHistoryItemVM? {
                nameLabel.text = model.name.value
                priceLabel.text = "$\(model.price.value.format(precision: 2, ignorePrecisionIfRounded: true))"
                
                if let optionLabel: UILabel = optionLabel {
                    optionLabel.text = model.option.value
                }
            }
        }
    }
}
