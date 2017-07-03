//
//  MerchantEditMenuDeleteTVC.swift
//  YQueue
//
//  Created by Aleksandr on 07/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantEditMenuDeleteTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var deleteButton: UIButton!
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: MerchantEditMenuDeleteVM = model as! MerchantEditMenuDeleteVM? {
                deleteButton.reactive.trigger(for: .touchUpInside)
                    .take(until: modelChangeSignal!)
                    .observeValues {
                        model.tapObserver?.send(value: ())
                }
            }
        }
    }
}
