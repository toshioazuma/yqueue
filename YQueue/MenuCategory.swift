//
//  MenuCategory.swift
//  YQueue
//
//  Created by Toshio on 21/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import AWSDynamoDB

class MenuCategory: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    static func dynamoDBTableName() -> String {
        return "MerchantCategories"
    }
    
    static func hashKeyAttribute() -> String {
        return "merchantId"
    }
    
    static func rangeKeyAttribute() -> String {
        return "id"
    }
    
    static func ignoreAttributes() -> [String] {
        return ["merchant"]
    }
    
    var merchantId: String = ""
    var id: String = ""
    var title: String = ""
    var position: Int = 0
    
    var merchant: Merchant!
}
