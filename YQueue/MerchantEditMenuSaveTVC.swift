//
//  MerchantEditMenuSaveTVC.swift
//  YQueue
//
//  Created by Toshio on 25/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantEditMenuSaveTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var saveButton: UIButton!
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: MerchantEditMenuSaveVM = model as! MerchantEditMenuSaveVM? {
                saveButton.reactive.trigger(for: .touchUpInside)
                    .take(until: modelChangeSignal!)
                    .observeValues {
                    model.tapObserver?.send(value: ())
                }
            }
        }
    }
}
