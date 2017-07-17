//
//  MerchantEditMenuAddOptionTVC.swift
//  YQueue
//
//  Created by Toshio on 25/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantEditMenuAddOptionTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var addButton: UIButton!
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: MerchantEditMenuAddOptionVM = model as! MerchantEditMenuAddOptionVM? {
                addButton.reactive.trigger(for: .touchUpInside)
                    .take(until: modelChangeSignal!)
                    .observeValues {
                    print("Add option button clicked")
                    model.tapObserver?.send(value: ())
                }
            }
        }
    }
}
