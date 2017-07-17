//
//  ToggleButton.swift
//  YQueue
//
//  Created by Toshio on 25/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class ToggleButton: UIButton {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        reactive.trigger(for: .touchUpInside)
            .take(during: reactive.lifetime)
            .observeValues { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                self.isSelected = !self.isSelected
            }
    }
}
