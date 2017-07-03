//
//  Animation.swift
//  YQueue
//
//  Created by Aleksandr on 05/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit

class Animation: NSObject {
    
    public static func moveOffset(forView view: UIView, offset: NSLayoutConstraint, delta: CGFloat,
                                  speed: CGFloat, delay: TimeInterval) {
        offset.constant = offset.constant + delta
        UIView.animate(withDuration: getDuration(distance: delta, speed: speed), delay: delay,
                       options: UIViewAnimationOptions(), animations: {
            view.layoutIfNeeded()
        }, completion: nil)
    }
    
    public static func moveOffset(forView view: UIView, offset: NSLayoutConstraint, delta: CGFloat,
                                  speed: CGFloat) -> TimeInterval {
        let duration = getDuration(distance: delta, speed: speed)
        
        offset.constant = offset.constant + delta
        UIView.animate(withDuration: duration) {
            view.layoutIfNeeded()
        }
        
        return duration
    }
    
    private static func getDuration(distance: CGFloat, speed: CGFloat) -> TimeInterval {
        return TimeInterval(abs(distance) / speed)
    }
}
