//
//  MerchantEditRestaurantCheckbox.swift
//  YQueue
//
//  Created by Aleksandr on 17/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantEditRestaurantCheckbox: UIView {

    @IBOutlet weak var normalImageView: UIImageView!
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var button: UIButton! {
        didSet {
            button.reactive.trigger(for: .touchUpInside).observeValues { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                self.selected.consume(!self.selected.value)
            }
        }
    }
    
    var selected = MutableProperty(false)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        selected.signal.observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.normalImageView.isHidden = $0
            self.selectedImageView.isHidden = !$0
        }
    }
}
