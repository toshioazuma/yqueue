//
//  MerchantSettingsTVC.swift
//  YQueue
//
//  Created by Toshio on 23/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantSettingsTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: MerchantSettingsVM = model as! MerchantSettingsVM? {
                iconImageView.image = model.icon
                titleLabel.text = model.title
            }
        }
    }
}
