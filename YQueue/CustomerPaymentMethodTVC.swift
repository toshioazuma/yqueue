//
//  CustomerPaymentMethodTVC.swift
//  YQueue
//
//  Created by Aleksandr on 05/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerPaymentMethodTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var buttonWrapper: UIView! {
        didSet {
            buttonWrapper.layer.cornerRadius = 5
            buttonWrapper.layer.borderColor = UIColor(white: 228.0/255.0, alpha: 1).cgColor
            buttonWrapper.layer.borderWidth = 0.5
        }
    }
    @IBOutlet weak var button: UIButton!
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var arrow: UIImageView!

    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: CustomerPaymentMethodVM = model as! CustomerPaymentMethodVM? {
                button.reactive.trigger(for: .touchUpInside).take(until: modelChangeSignal!).observeValues {
                    model.tapObserver?.send(value: ())
                }
                
                iconImageView.reactive.image <~ model.icon.signal.take(until: modelChangeSignal!)
                label.reactive.text <~ model.text.signal.take(until: modelChangeSignal!)
                label.reactive.textColor <~ model.textColor.signal.take(until: modelChangeSignal!)
                arrow.reactive.image <~ model.arrowImage.signal.take(until: modelChangeSignal!)
            }
        }
    }
}
