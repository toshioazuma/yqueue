//
//  Order.swift
//  YQueue
//
//  Created by Aleksandr on 08/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import AWSDynamoDB

class Order: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    static func dynamoDBTableName() -> String {
        return "Orders"
    }
    
    static func hashKeyAttribute() -> String {
        return "merchantId"
    }
    
    static func rangeKeyAttribute() -> String {
        return "id"
    }
    
    static func ignoreAttributes() -> [String] {
        return ["primaryColor", "type", "dateTime", "merchant", "basket", "isPaid", "isPickedUp", "isCompleted", "isHiddenByCustomer", "isHiddenByMerchant", "isFeedbackSent"]
    }
    
    enum `Type`: Int {
        case takeAway, dineIn
    }
    
    var primaryColor: UIColor {
        get {
            return type == .takeAway
                ? UIColor(red: 245.0/255.0, green: 114.0/255.0, blue: 90.0/255.0, alpha: 1)
                : UIColor(red: 255.0/255.0, green: 143.0/255.0, blue: 0.0/255.0, alpha: 1)
        }
    }
    
    var totalPriceWithTax: Double {
        get {
            let total = basket.items.map{ $0.totalPrice }.reduce(0, +)
            let tax = total * merchant.tax / 100.0
            let grandTotal = round((total+tax) * 100.0) / 100.0
            
            return grandTotal
        }
    }
    
    var merchantId: String!
    var id = ""
    var number: Int = 0
    var tableNumber: String = "" {
        didSet {
            if tableNumber == "" {
                tableNumber = AWS.emptyString
            }
        }
    }
    var typeNumber = 0 {
        didSet {
            type = Type(rawValue: typeNumber)!
        }
    }
    var dateTimeNumber = 0.0 {
        didSet {
            dateTime = Date(timeIntervalSince1970: dateTimeNumber)
        }
    }
    var customerUsername: String = ""
    var customerName: String = "" {
        didSet {
            if customerName == "" {
                customerName = AWS.emptyString
            }
        }
    }
    var customeriOsToken: String = "" {
        didSet {
            if customeriOsToken == "" {
                customeriOsToken = AWS.emptyString
            }
        }
    }
    var customerAndroidToken: String = "" {
        didSet {
            if customerAndroidToken == "" {
                customerAndroidToken = AWS.emptyString
            }
        }
    }
    var basketJSONArrayString: String = "[]" {
        didSet {
            basket = Basket()
            
            let itemsJSONArray: Array<Dictionary<String, Any>>
                = try! JSONSerialization.jsonObject(with: basketJSONArrayString.data(using: .utf8)!,
                                                    options: JSONSerialization.ReadingOptions())
                    as! Array<Dictionary<String, Any>>
            for itemJSONObject in itemsJSONArray {
                let count = itemJSONObject["count"] as! Int
                
                var option: MenuItem.Option? = nil
                if let optionJSONObject: Dictionary<String, Any> = itemJSONObject["option"] as! Dictionary<String, Any>? {
                    option = MenuItem.Option(id: "",
                                             name: optionJSONObject["name"] as! String,
                                             price: optionJSONObject["price"] as! Double)
                }
                
                let menuItemJSONObject: Dictionary<String, Any> = itemJSONObject["menuItem"] as! Dictionary<String, Any>
                let menuItem: MenuItem = MenuItem()
                menuItem.categoryId = menuItemJSONObject["categoryId"] as! String!
                menuItem.id = menuItemJSONObject["id"] as! String!
                menuItem.name = menuItemJSONObject["name"] as! String
                menuItem.price = menuItemJSONObject["price"] as! Double
                menuItem.number = menuItemJSONObject["number"] as! String
                
                for _ in 1...count {
                    basket.add(menuItem, option: option)
                }
            }
        }
    }
    var total: Double = 0.0
    var paid: Int = 0
    var pickedUp: Int = 0
    var completed: Int = 0
    var hiddenByCustomer: Int = 0
    var hiddenByMerchant: Int = 0
    var feedbackSent: Int = 0
    
    var merchant: Merchant!
    var type: Type!
    var dateTime: Date!
    var basket: Basket!
    
    #if CUSTOMER
    
    func prepareForSave() {
        if id == "" {
            id = UUID().uuidString.lowercased()
        }
        
        merchantId = merchant.id
        typeNumber = type.rawValue
        // round to 6 digits after comma because of DynamoDB values limit
        print("dateTime seconds = \(String(format: "%f", dateTimeNumber))")
        dateTimeNumber = round(dateTime.timeIntervalSince1970 * 1000000.0)/1000000.0
        print("dateTimeNumer = \(String(format: "%f", dateTimeNumber))")
        
        customerUsername = Api.auth.username!
        customerName = Api.auth.name!
        customeriOsToken = Api.auth.pushToken ?? AWS.emptyString
        customerAndroidToken = AWS.emptyString
        
        var basketJSONArrayString = "[]"
        if basket.items.count > 0 {
            var basketJSONArray = Array<Dictionary<String, Any>>()
            for item in basket.items {
                var basketJSONObject = Dictionary<String, Any>()
                basketJSONObject["count"] = item.count
                
                if let option: MenuItem.Option = item.option {
                    var optionJSONObject = Dictionary<String, Any>()
                    optionJSONObject["name"] = option.name
                    optionJSONObject["price"] = option.price
                    basketJSONObject["option"] = optionJSONObject
                }
                
                var menuItemJSONObject = Dictionary<String, Any>()
                menuItemJSONObject["categoryId"] = item.menuItem.categoryId
                menuItemJSONObject["id"] = item.menuItem.id
                menuItemJSONObject["name"] = item.menuItem.name
                menuItemJSONObject["price"] = item.menuItem.price
                menuItemJSONObject["number"] = item.menuItem.number
                basketJSONObject["menuItem"] = menuItemJSONObject
                
                basketJSONArray.append(basketJSONObject)
            }
            
            basketJSONArrayString = String(data: try! JSONSerialization.data(withJSONObject: basketJSONArray,
                                                                             options: JSONSerialization.WritingOptions()),
                                            encoding: .utf8)!
        }
        self.basketJSONArrayString = basketJSONArrayString
        
        let total = basket.items.map{ $0.totalPrice }.reduce(0, +)
        let tax = total * merchant.tax / 100.0
        let grandTotal = round((total+tax) * 100.0) / 100.0
        
        self.total = grandTotal
    }
    
    #endif
    
    
    
    var isPaid: Bool {
        get {
            return paid == 1
        } set {
            paid = newValue ? 1 : 0
        }
    }
    var isPickedUp: Bool {
        get {
            return pickedUp == 1
        } set {
            pickedUp = newValue ? 1 : 0
        }
    }
    var isCompleted: Bool {
        get {
            return completed == 1
        } set {
            completed = newValue ? 1 : 0
        }
    }
    var isHiddenByCustomer: Bool {
        get {
            return hiddenByCustomer == 1
        } set {
            hiddenByCustomer = newValue ? 1 : 0
        }
    }
    var isHiddenByMerchant: Bool {
        get {
            return hiddenByMerchant == 1
        } set {
            hiddenByMerchant = newValue ? 1 : 0
        }
    }
    var isFeedbackSent: Bool {
        get {
            return feedbackSent == 1
        } set {
            feedbackSent = newValue ? 1 : 0
        }
    }
}
