//
//  ViewExtension.swift
//  YQueue
//
//  Created by Toshio on 19/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit

extension UIView {
    func roundCorners() {
        layoutIfNeeded()
        layer.cornerRadius = frame.size.height / 2.0
    }
}
