//
//  Merchant.swift
//  YQueue
//
//  Created by Aleksandr on 05/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import MapKit
import AWSDynamoDB

class Merchant: AWSDynamoDBObjectModel, AWSDynamoDBModeling, MKAnnotation {
    
    static func dynamoDBTableName() -> String {
        return "Merchants"
    }
    
    static func hashKeyAttribute() -> String {
        return "id"
    }
    
    static func ignoreAttributes() -> [String] {
        return ["coordinate", "menuCategories", "iOSPushTokens", "androidPushTokens", "isTakeAwayAvailable", "isDineInAvailable"]
    }
    
    public var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2DMake(latitude, longitude)
        }
    }

    var id: String!
    var number: Int = 0
    var title: String?
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var workingFrom: Int = 0
    var workingTo: Int = 1440
    var gst: Double = 0.0
    var tax: Double = 0.0
    var takeAwayAvailable: Int = 1
    var dineInAvailable: Int = 1
    
    var isTakeAwayAvailable: Bool {
        get {
            return takeAwayAvailable == 1
        } set {
            takeAwayAvailable = newValue ? 1 : 0
        }
    }
    
    var isDineInAvailable: Bool {
        get {
            return dineInAvailable == 1
        } set {
            dineInAvailable = newValue ? 1 : 0
        }
    }
    
    var iOSPushTokensJSONArrayString: String = "[]" {
        didSet {
            self.iOSPushTokens.removeAll()
            let iOSPushTokens: Array<String>
                = try! JSONSerialization.jsonObject(with: iOSPushTokensJSONArrayString.data(using: .utf8)!,
                                                    options: JSONSerialization.ReadingOptions())
                    as! Array<String>
            self.iOSPushTokens.append(contentsOf: iOSPushTokens)
        }
    }
    var androidPushTokensJSONArrayString: String = "[]" {
        didSet {
            self.androidPushTokens.removeAll()
            let androidPushTokens: Array<String>
                = try! JSONSerialization.jsonObject(with: androidPushTokensJSONArrayString.data(using: .utf8)!,
                                                    options: JSONSerialization.ReadingOptions())
                    as! Array<String>
            self.androidPushTokens.append(contentsOf: androidPushTokens)
        }
    }
    
    var menuCategories = [MenuCategory]() {
        didSet {
            for menuCategory in menuCategories {
                menuCategory.merchant = self
            }
        }
    }
    var iOSPushTokens = [String]()
    var androidPushTokens = [String]()
    
    var owner: String = ""
    var users: Set<String>! = []
    
    func prepareForSave() {
        var iOSPushTokensJSONArrayString = "[]"
        if iOSPushTokens.count > 0 {
            iOSPushTokensJSONArrayString = String(data: try! JSONSerialization.data(withJSONObject: iOSPushTokens,
                                                                                    options: JSONSerialization.WritingOptions()),
                                                  encoding: .utf8)!
        }
        self.iOSPushTokensJSONArrayString = iOSPushTokensJSONArrayString
        
        var androidPushTokensJSONArrayString = "[]"
        if androidPushTokens.count > 0 {
            androidPushTokensJSONArrayString = String(data: try! JSONSerialization.data(withJSONObject: androidPushTokens,
                                                                                        options: JSONSerialization.WritingOptions()),
                                                      encoding: .utf8)!
        }
        self.androidPushTokensJSONArrayString = androidPushTokensJSONArrayString
    }
}
