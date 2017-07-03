//
//  BorderedTextField.swift
//  YQueue
//
//  Created by Aleksandr on 08/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit

class BorderedTextField: UITextField {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        layer.cornerRadius = 5
        layer.borderColor = UIColor(white: 228.0/255.0, alpha: 1).cgColor
        layer.borderWidth = 1
    }
    
    let padding: CGFloat = 8.0
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: padding, dy: 0)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: padding, dy: 0)
    }
}
