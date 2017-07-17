//
//  CustomerChangePasswordInput.swift
//  YQueue
//
//  Created by Toshio on 06/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit

class CustomerChangePasswordInput: UIView {

    @IBOutlet weak var textField: UITextField! {
        didSet {
            layer.cornerRadius = 3.5
            layer.borderWidth = 0.5
            layer.borderColor = UIColor(white: 202.0/255.0, alpha: 1).cgColor
        }
    }
    
    @IBOutlet weak var checkmark: UIImageView!
    
    func clear() {
        textField.text = ""
        textField.sendActions(for: .editingChanged)
    }
}
