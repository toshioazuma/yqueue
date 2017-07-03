//
//  CustomerReceiptChargedTVC.swift
//  YQueue
//
//  Created by Aleksandr on 07/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerReceiptChargedTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var cardTypeImageView: UIImageView!
    @IBOutlet weak var cardMaskLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: CustomerReceiptChargedVM = model as! CustomerReceiptChargedVM? {
                cardTypeImageView.image = model.icon.value
                cardMaskLabel.text = model.text.value
                totalLabel.text = "$\(model.charged.value.format(precision: 2, ignorePrecisionIfRounded: true))"
            }
        }
    }
}
