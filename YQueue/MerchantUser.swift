//
//  MerchantUser.swift
//  YQueue
//
//  Created by Toshio on 27/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import AWSDynamoDB

class MerchantUser: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    enum Access: Int {
        case owner, staff
    }
    
    static func dynamoDBTableName() -> String {
        return "MerchantUsers"
    }
    
    static func hashKeyAttribute() -> String {
        return "email"
    }
    
    static func ignoreAttributes() -> [String] {
        return ["merchant", "access"]
    }

    var merchantId: String!
    var email: String = ""
    var accessValue: Int = 0
    
    var merchant: Merchant!
    
    var access: Access {
        get {
            return Access(rawValue: accessValue)!
        } set {
            accessValue = newValue.rawValue
        }
    }
}
