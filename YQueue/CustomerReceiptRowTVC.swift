//
//  CustomerReceiptRowTVC.swift
//  YQueue
//
//  Created by Aleksandr on 07/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerReceiptRowTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: CustomerReceiptRowVM = model as! CustomerReceiptRowVM? {
                titleLabel.text = model.title.value
                priceLabel.text = "$\(model.price.value.format(precision: 2, ignorePrecisionIfRounded: true))"
                
                if let subTitleLabel: UILabel = subTitleLabel {
                    subTitleLabel.text = model.subTitle.value
                }
            }
        }
    }
}
