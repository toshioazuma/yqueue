//
//  PaymentMethod.swift
//  YQueue
//
//  Created by Toshio on 07/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class PaymentMethod: NSObject {
    
    var cardNumber = ""
    var holderName = ""
    var expMonth = ""
    var expYear = ""
    var cvv = ""
    var type = ""
    var token = ""
    var tokenLastUsed = ""
    
    static func get() -> [PaymentMethod] {
        var paymentMethods = [PaymentMethod]()
        
        let storageName = "payment_".appending(Api.auth.username!)
        if let raw: Array<Dictionary<String, String>> = EncryptedStorage(name: storageName).load() as! Array<Dictionary<String, String>>? {
            print("raw = \(raw)")
            for item: Dictionary<String, String> in raw {
                let method = PaymentMethod()
                method.cardNumber = item["card_number"]!
                method.holderName = item["holder_name"]!
                method.expMonth = item["exp_month"]!
                method.expYear = item["exp_year"]!
                method.cvv = item["cvv"]!
                method.token = item["token"]!
                method.type = item["type"]!
                method.tokenLastUsed = item["token_last_used"]!
                
                paymentMethods.append(method)
            }
        }
        
        return paymentMethods
    }
    
    static func save(_ paymentMethods: [PaymentMethod]) {
        var raw = Array<Dictionary<String, String>>()
        
        for method in paymentMethods {
            var item = Dictionary<String, String>()
            item["card_number"] = method.cardNumber
            item["holder_name"] = method.holderName
            item["exp_month"] = method.expMonth
            item["exp_year"] = method.expYear
            item["cvv"] = method.cvv
            item["token"] = method.token
            item["token_last_used"] = method.tokenLastUsed
            item["type"] = method.type
            
            raw.append(item)
        }
        
        let storageName = "payment_".appending(Api.auth.username!)
        EncryptedStorage(name: storageName).save(raw)
    }
}

extension Int {
    var monthWithLeadingZeroValue: String {
        get {
            return self > 10 ? String(self) : "0\(self)"
        }
    }
}
