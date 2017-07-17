//
//  CustomerMenuOptionAlertTVC.swift
//  YQueue
//
//  Created by Toshio on 12/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerMenuOptionAlertTVC: UITableViewCell, ModelTableViewCellProtocol {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var checkmark: UIImageView!
    
    var labelNormalTextColor: UIColor {
        return UIColor(white: 20.0/255.0, alpha: 1)
    }

    var labelSelectedTextColor: UIColor {
        return UIColor(red: 50.0/255.0, green: 209.0/255.0, blue: 125.0/255.0, alpha: 1)
    }
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: CustomerMenuOptionAlertVM = model as! CustomerMenuOptionAlertVM? {
                nameLabel.text = model.option.name
                nameLabel.textColor = model.selected.value ? labelSelectedTextColor : labelNormalTextColor
                
                priceLabel.text = "$".appending(model.option.price.format(precision: 2, ignorePrecisionIfRounded: true))
                priceLabel.textColor = model.selected.value ? labelSelectedTextColor : labelNormalTextColor
                
                checkmark.isHidden = !model.selected.value
            }
        }
    }
}
