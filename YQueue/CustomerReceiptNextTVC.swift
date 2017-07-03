//
//  CustomerReceiptNextTVC.swift
//  YQueue
//
//  Created by Aleksandr on 06/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerReceiptNextTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var button: UIButton! {
        didSet {
            button.layer.cornerRadius = 24.5
            button.addTarget(self, action: #selector(toggle), for: .touchUpInside)
        }
    }
    
    @objc private func toggle() {
        button.isSelected = !button.isSelected
    }
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: CustomerReceiptNextVM = model as! CustomerReceiptNextVM? {
                button.reactive.trigger(for: .touchUpInside)
                    .take(until: modelChangeSignal!)
                    .observeValues {
                        model.tapObserver?.send(value: ())
                }
            }
        }
    }
}
