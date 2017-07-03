//
//  CustomerPayTVC.swift
//  YQueue
//
//  Created by Aleksandr on 05/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerPayTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var button: UIButton! {
        didSet {
            button.layer.cornerRadius = 24.5
        }
    }
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: CustomerPayVM = model as! CustomerPayVM? {
                button.reactive.trigger(for: .touchUpInside)
                    .take(until: modelChangeSignal!)
                    .observeValues {
                        model.tapObserver?.send(value: ())
                }
            }
        }
    }
}
