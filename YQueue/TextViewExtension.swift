//
//  TextViewExtension.swift
//  YQueue
//
//  Created by Aleksandr on 27/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

extension UITextView {
    func setCharactersLimit(_ limit: Int) {
        reactive.continuousTextValues
            .filter { ($0.characters.count) > limit }
            .take(during: reactive.lifetime)
            .observe { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                if let text: String = $0.value! {
                    self.text = text.limit(limit)
                }
        }
    }
    
}
