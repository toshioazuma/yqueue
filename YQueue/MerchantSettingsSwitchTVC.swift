//
//  MerchantSettingsSwitchTVC.swift
//  YQueue
//
//  Created by Aleksandr on 23/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantSettingsSwitchTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var switchView: UISwitch!
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: MerchantSettingsSwitchVM = model as! MerchantSettingsSwitchVM? {
                iconImageView.image = model.icon
                titleLabel.text = model.title
                
                switchView.reactive.isOn <~ model.switched.signal
                    .take(until: modelChangeSignal!)
                
                switchView.reactive.isEnabled <~ model.switchingEnabled.signal
                    .take(until: modelChangeSignal!)
                
                switchView.reactive.isOnValues
                    .take(until: modelChangeSignal!)
                    .filter { $0 != model.switched.value }
                    .observeValues {
                    model.switched.consume($0)
                    model.tapObserver?.send(value: ())
                }
            }
        }
    }
}
