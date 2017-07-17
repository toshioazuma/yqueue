//
//  CustomerRewardsCouponsTVC.swift
//  YQueue
//
//  Created by Toshio on 05/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerRewardsCouponsTVC: UITableViewCell, ModelTableViewCellProtocol {

    @IBOutlet weak var buttonWrapper: UIView! {
        didSet {
            buttonWrapper.layer.cornerRadius = 5
            buttonWrapper.layer.borderColor = UIColor(white: 228.0/255.0, alpha: 1).cgColor
            buttonWrapper.layer.borderWidth = 1
        }
    }
    
    @IBOutlet weak var button: UIButton!
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: CustomerRewardsCouponsVM = model as! CustomerRewardsCouponsVM? {
                button.reactive.trigger(for: .touchUpInside)
                    .take(until: modelChangeSignal!)
                    .observeValues {
                        model.tapObserver?.send(value: ())
                    }
            }
        }
    }
}
