//
//  DoubleExtension.swift
//  YQueue
//
//  Created by Toshio on 05/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import Foundation

extension Double {
    func format(precision: Int, ignorePrecisionIfRounded: Bool) -> String {
        var precision = precision
        if ignorePrecisionIfRounded && self-floor(self) == 0 {
            precision = 0
        }
        
        return String(format: "%.\(precision)f", self)
    }
    
    func format(precision: Int) -> String {
        return format(precision: precision, ignorePrecisionIfRounded: false)
    }
}
