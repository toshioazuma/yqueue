//
//  SearchTextField.swift
//  YQueue
//
//  Created by Toshio on 08/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit

class SearchTextField: UITextField {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        layer.cornerRadius = 15
    }
    
    let leftPadding: CGFloat = 43.0
    let rightPadding: CGFloat = 8.0
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: leftPadding,
                      y: 0,
                      width: bounds.size.width-leftPadding-rightPadding,
                      height: bounds.size.height)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: leftPadding,
                      y: 0,
                      width: bounds.size.width-leftPadding-rightPadding,
                      height: bounds.size.height)
    }
}
