//
//  Push.swift
//  YQueue
//
//  Created by Toshio on 19/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result
import AWSSNS

class Push: NSObject {
    
    #if DEBUG
    private static let iOS_CustomerArn = "arn:aws:sns:ap-northeast-1:268310197857:app/APNS_SANDBOX/YQueue_Customer"
    private static let iOS_MerchantArn = "arn:aws:sns:ap-northeast-1:268310197857:app/APNS_SANDBOX/YQueue_Merchant"
    #else
    private static let iOS_CustomerArn = "arn:aws:sns:ap-northeast-1:268310197857:app/APNS/YQueue_Customer"
    private static let iOS_MerchantArn = "arn:aws:sns:ap-northeast-1:268310197857:app/APNS/YQueue_Merchant"
    #endif
    private static let android_CustomerArn = ""
    private static let android_MerchantArn = ""
    
    var openedWithNotification = false
    
    #if MERCHANT
    var newOrderSignal: Signal<Order, NoError>
    var newOrderObserver: Observer<Order, NoError>
    #endif
    
    override init() {
        #if MERCHANT
            (newOrderSignal, newOrderObserver) = Signal<Order, NoError>.pipe()
        #endif
        super.init()
    }
    
    #if MERCHANT
        var printingEnabled: Bool {
            get {
                let username: String = Api.auth.username!
                return UserDefaults.standard.bool(forKey: username.md5().appending("_printing_enabled"))
            } set {
                let username: String = Api.auth.username!
                UserDefaults.standard.set(newValue, forKey: username.md5().appending("_printing_enabled"))
            }
        }
    #endif
    
    var token: String? {
        get {
            let username: String = Api.auth.username!
            return UserDefaults.standard.string(forKey: username.md5().appending("_push_token"))
        } set {
            let username: String = Api.auth.username!
            let key = username.md5().appending("_push_token")
            
            #if MERCHANT
                if let oldToken: String = UserDefaults.standard.string(forKey: key) {
                    print("has old token")
                    if newValue == nil {
                        print("new token missing, remove old token")
                        Api.auth.remove(pushToken: oldToken)
                    } else if let token: String = newValue {
                        print("has new token instead of old, replace it")
                        Api.auth.replace(pushToken: oldToken, with: token)
                    }
                } else {
                    print("has no old token, just set new")
                    if let token: String = newValue {
                        Api.auth.set(pushToken: token)
                    }
                }
            #endif
            
            UserDefaults.standard.set(newValue, forKey: key)
            UserDefaults.standard.synchronize()
        }
    }
    
    func unregister() {
        token = nil
//        printingEnabled = false
        UIApplication.shared.unregisterForRemoteNotifications()
    }
    
    func register() {
        let notificationSettings = UIUserNotificationSettings.init(types: [.alert, .badge], categories: nil)
        
        UIApplication.shared.registerUserNotificationSettings(notificationSettings)
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    #if CUSTOMER
    
    func paid(order: Order) {
        var orderStringObjects = [String]()
        for item in order.basket.items {
            var stringObject = "\(item.count) \(item.menuItem.name)"
            if let option: MenuItem.Option = item.option {
                stringObject = stringObject.appending(" - ").appending(option.name)
            }
            orderStringObjects.append(stringObject)
        }
        
        let total = order.basket.items.map{ $0.totalPrice }.reduce(0, +)
        let tax = total * order.merchant.tax / 100.0
        let messageObjects = ["Type: ".appending(order.type == .takeAway ? "Take Away Order" : "Dine In Order | Table no. ".appending(order.tableNumber)),
                              "Client: ".appending(Api.auth.name!),
                              "Total: $".appending(order.totalPriceWithTax.format(precision: 2, ignorePrecisionIfRounded: true)),
                              "Order: ".appending(orderStringObjects.joined(separator: ", "))]
        let message = messageObjects.joined(separator: " | ")
        print("push message: \(message)")
        
        // check for ACTUAL tokens
        let sendBlock: ([String], [String]) -> Void = {
            let iOSPushTokens = $0
            let androidPushTokens = $1
            
            if iOSPushTokens.count > 0 {
                self.send(message: message,
                          forOrder: order,
                          iOSPushTokens: iOSPushTokens,
                          arn: Push.iOS_MerchantArn)
            }
            
            if androidPushTokens.count > 0 {
                self.send(message: message,
                          forOrder: order,
                          iOSPushTokens: androidPushTokens,
                          arn: Push.android_MerchantArn)
            }
        }
        
        AWS.objectMapper.load(Merchant.self, hashKey: order.merchantId, rangeKey: nil).continue( { (task: AWSTask<AnyObject>) -> Any? in
            print("Received merchant = \(task.result)")
            if let merchant: Merchant = task.result as! Merchant? {
                print("send NEW ios push tokens = \(merchant.iOSPushTokens)")
                sendBlock(merchant.iOSPushTokens, merchant.androidPushTokens)
            } else {
                print("send OLD ios push tokens = \(order.merchant.iOSPushTokens)")
                sendBlock(order.merchant.iOSPushTokens, order.merchant.androidPushTokens)
            }
            
            return nil
        })
    }
    
    #endif
    
    #if MERCHANT
    
    func pickedUp(order: Order) {
        let message = "Your order #\(Api.auth.merchantUser.merchant.number)-\(order.number) has been picked up"
        
        if order.customeriOsToken.aws.characters.count > 0 {
            send(message: message,
                 forOrder: order,
                 iOSPushTokens: [order.customeriOsToken],
                 arn: Push.iOS_CustomerArn)
        }
        
        if order.customerAndroidToken.aws.characters.count > 0 {
            send(message: message,
                 forOrder: order,
                 iOSPushTokens: [order.customerAndroidToken],
                 arn: Push.android_CustomerArn)
        }
    }
    
    func completed(order: Order) {
        var message = ""
        if order.type == .takeAway {
            message = "Your order #\(Api.auth.merchantUser.merchant.number)-\(order.number) is now ready for collection"
        } else {
            let total = order.basket.items.map{ $0.totalPrice }.reduce(0, +)
            message = "Thanks for visiting \(order.merchant.title!), your total meal cost was $\(total.format(precision: 2, ignorePrecisionIfRounded: true))"
        }
            
        if order.customeriOsToken.aws.characters.count > 0 {
            send(message: message,
                 forOrder: order,
                 iOSPushTokens: [order.customeriOsToken],
                 arn: Push.iOS_CustomerArn)
        }
        
        if order.customerAndroidToken.aws.characters.count > 0 {
            send(message: message,
                 forOrder: order,
                 androidPushTokens: [order.customerAndroidToken],
                 arn: Push.android_CustomerArn)
        }
    }
    
    #endif
    
    private func send(message: String, forOrder order: Order, iOSPushTokens: [String], arn: String) {
        let messageObject = [
            "priority" : "high",
            "id" : order.id,
            "merchant_id" : order.merchantId,
            "aps" : [
                "alert" : message,
                "sound" : "default",
                "badge" : 1
            ]
        ] as [String : Any]
        let messageJsonData = try! JSONSerialization.data(withJSONObject: messageObject, options: JSONSerialization.WritingOptions())
        let pushMessage = String(data: messageJsonData, encoding: .utf8)
        
//        let pushMessage = "{\"priority\":\"high\",\"id\":\"\(order.id)\",\"merchantId\":\"\(order.merchantId)\",\"aps\":{\"alert\": \"\(message)\",\"sound\":\"default\", \"badge\":\"1\"} }"
        let dict = ["default" : message,
                    "APNS_SANDBOX" : pushMessage,
                    "APNS" : pushMessage]
        let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions())
        let jsonMessage = String(data: jsonData, encoding: .utf8)
        
        for token in iOSPushTokens {
            let input: AWSSNSCreatePlatformEndpointInput = AWSSNSCreatePlatformEndpointInput()
            input.token = token
            input.platformApplicationArn = arn
            
            AWS.sns.createPlatformEndpoint(input).continue({ (task: AWSTask<AWSSNSCreateEndpointResponse>) -> Any? in
                if let result: AWSSNSCreateEndpointResponse = task.result,
                    let endpointArn = result.endpointArn {
                    let input: AWSSNSPublishInput = AWSSNSPublishInput()
                    input.targetArn = endpointArn
                    input.message = jsonMessage
                    input.messageStructure = "json"
                    AWS.sns.publish(input).continue({ (task: AWSTask<AWSSNSPublishResponse>) -> Any? in
                        print("sns error = \(task.error)")
                        return nil
                    })
                }
                
                return nil
            })
        }
    }
    
    private func send(message: String, forOrder order: Order, androidPushTokens: [String], arn: String) {
    }
}
