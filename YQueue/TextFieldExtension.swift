//
//  TextFieldExtension.swift
//  YQueue
//
//  Created by Aleksandr on 25/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

extension UITextField {
    func setCharactersLimit(_ limit: Int) {
        reactive.continuousTextValues
            .filter { ($0?.characters.count)! > limit }
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
    
    func textWithoutPrefix(_ prefix: String) -> String {
        if let text: String = text {
            if text.hasPrefix(prefix) {
                return text.replacingOccurrences(of: prefix, with: "")
            } else if prefix.hasPrefix(text) {
                return ""
            }
        }
        
        return ""
    }
    
    func setPrefix(_ prefix: String, limit: Int) {
        reactive.continuousTextValues
            .take(during: reactive.lifetime)
            .filter {
                if let text: String = $0 {
                    return !text.hasPrefix(prefix) ||
                        text.replacingOccurrences(of: prefix, with: "").characters.count > limit
                }
                return true
            }
            .observeValues { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                if var text: String = $0 {
                    if text.hasPrefix(prefix) {
                        text = text.replacingOccurrences(of: prefix, with: "")
                    } else if prefix.hasPrefix(text) {
                        text = ""
                    }
                    self.text = prefix.appending(text.limit(limit))
                }
            }
    }
    
    func resignFirstResponderOnReturnButton() {
        reactive.trigger(for: .editingDidEndOnExit)
            .take(during: reactive.lifetime)
            .observeValues { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                self.resignFirstResponder()
            }
    }
}
