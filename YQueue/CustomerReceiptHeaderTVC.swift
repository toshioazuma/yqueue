//
//  CustomerReceiptHeaderTVC.swift
//  YQueue
//
//  Created by Aleksandr on 06/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerReceiptHeaderTVC: UITableViewCell, ModelTableViewCellProtocol {
        
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!

    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: CustomerReceiptHeaderVM = model as! CustomerReceiptHeaderVM? {
                nameLabel.text = model.merchant.title
                idLabel.text = "Order Number: #"
                    .appending(String(model.order.merchant.number))
                    .appending("-")
                    .appending(String(model.order.number))
            }
        }
    }
}
