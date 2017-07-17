//
//  NavigationBarExtension.swift
//  YQueue
//
//  Created by Toshio on 05/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit

extension UINavigationBar {
    
    func setBottomBorderColor(color: UIColor, height: CGFloat) {
        let bottomBorderRect = CGRect(x: 0, y: frame.height, width: frame.width, height: height)
        let bottomBorderView = UIView(frame: bottomBorderRect)
        bottomBorderView.backgroundColor = color
        addSubview(bottomBorderView)
    }
}
