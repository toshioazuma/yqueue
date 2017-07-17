//
//  Reward.swift
//  YQueue
//
//  Created by Toshio on 12/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit

class Reward: NSObject {
    
    var merchant: Merchant
    var title: String
    var validDate: Date
    
    init(merchant: Merchant, title: String, validDate: Date) {
        self.merchant = merchant
        self.title = title
        self.validDate = validDate
        
        super.init()
    }
    
    public static func testData(callback: @escaping (_ merchants: Array<Reward>) -> Void) {
//        Merchant.testData { (merchants: Array<Merchant>) in
//            let titles = ["Pizza", "Drink", "Temaki", "Soup", "Coffee"]
//            
//            var rewards = Array<Reward>()
//            for merchant in merchants {
//                for title in titles {
//                    var offset = DateComponents()
//                    offset.day = 15+Int(arc4random_uniform(90))
//                    
//                    rewards.append(Reward(merchant: merchant,
//                                          title: "1 Free \(title)",
//                                          validDate: Calendar.current.date(byAdding: offset,
//                                                                           to: Date())!))
//                }
//            }
//            
//            callback(rewards)
//        }
    }
}
