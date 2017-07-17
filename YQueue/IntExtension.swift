//
//  IntExtension.swift
//  YQueue
//
//  Created by Toshio on 23/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import Foundation

extension Int {
    var workingHoursAndMinutes: String {
        let hours = self/60
        let minutes = self-hours*60
        
        var string = ""
        if hours < 10 {
            string = "0"
        }
        string += "\(hours):"
        
        if minutes < 10 {
            string += "0"
        }
        string += "\(minutes)"
        
        return string
    }
}
