//
//  OrderFeedback.swift
//  YQueue
//
//  Created by Toshio on 27/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import AWSDynamoDB

class OrderFeedback: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    static func dynamoDBTableName() -> String {
        return "OrderFeedback"
    }
    
    static func hashKeyAttribute() -> String {
        return "merchantId"
    }
    
    static func rangeKeyAttribute() -> String {
        return "id"
    }
    
    static func ignoreAttributes() -> [String] {
        return ["order", "merchant", "dateTime"]
    }
    
    var merchantId: String!
    var id = ""
    var qualityOfFood: Int = 0
    var qualityOfService: Int = 0
    var ambience: Int = 0
    var comment: String = "" {
        didSet {
            if comment == "" {
                comment = AWS.emptyString
            }
        }
    }
    var dateTimeNumber: Double = 0.0 {
        didSet {
            dateTime = Date(timeIntervalSince1970: dateTimeNumber)
        }
    }
    
    var order: Order!
    var merchant: Merchant!
    var dateTime: Date!
    
    func prepareForSave() {
        id = order.id
        merchantId = merchant.id
        dateTimeNumber = round(dateTime.timeIntervalSince1970 * 1000000.0)/1000000.0
    }
}
