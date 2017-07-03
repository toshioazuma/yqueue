//
//  CustomerSettingsTVC.swift
//  YQueue
//
//  Created by Aleksandr on 06/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerSettingsTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: CustomerSettingsVM = model as! CustomerSettingsVM? {
                iconImageView.image = model.icon
                titleLabel.text = model.title
            }
        }
    }
}
