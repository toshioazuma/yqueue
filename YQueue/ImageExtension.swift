//
//  ImageExtension.swift
//  YQueue
//
//  Created by Aleksandr on 13/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit

extension UIImage {
    func resized(to newSize: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
