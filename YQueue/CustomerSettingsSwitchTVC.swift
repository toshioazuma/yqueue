
//
//  CustomerSettingsSwitchTVC.swift
//  YQueue
//
//  Created by Toshio on 23/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerSettingsSwitchTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var switchView: UISwitch!
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: CustomerSettingsSwitchVM = model as! CustomerSettingsSwitchVM? {
                iconImageView.image = model.icon
                titleLabel.text = model.title
                
                switchView.isOn = model.switched
                switchView.reactive.isOnValues.take(until: modelChangeSignal!).observeValues {
                    model.switched = $0
                    model.tapObserver?.send(value: ())
                }
            }
        }
    }
}
