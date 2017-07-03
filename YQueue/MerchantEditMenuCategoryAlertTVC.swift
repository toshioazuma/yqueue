//
//  MerchantEditMenuCategoryAlertTVC.swift
//  YQueue
//
//  Created by Aleksandr on 25/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantEditMenuCategoryAlertTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var label: UILabel!
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
            if let model: MerchantEditMenuCategoryAlertVM = model as! MerchantEditMenuCategoryAlertVM? {
                if let menuCategory: MenuCategory = model.menuCategory {
                    label.text = menuCategory.title
                    label.textColor = model.selected.value ? self.labelSelectedTextColor : self.labelNormalTextColor
                    
                    checkmark.isHidden = !model.selected.value
                } else {
                    label.text = "Add new category"
                    label.textColor = self.labelNormalTextColor
                    checkmark.isHidden = true
                }
            }
        }
    }
}
