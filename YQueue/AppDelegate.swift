//
//  AppDelegate.swift
//  YQueue
//
//  Created by Toshio on 03/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result
import FBSDKCoreKit
import AWSDynamoDB
import AWSS3

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)

//        AWS.objectMapper.scan(MenuCategory.self, expression: AWSDynamoDBScanExpression()).continue( { (task: AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
//            for category in task.result?.items as! [MenuCategory] {
//                let expr = AWSDynamoDBQueryExpression()
//                expr.keyConditionExpression = "categoryId = :categoryId"
//                expr.expressionAttributeValues = [":categoryId":category.id]
//                
//                AWS.objectMapper.query(MenuItem.self, expression: expr).continue({ (task: AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
//                    for item in task.result?.items as! [MenuItem] {
//                        item.merchantId = category.merchantId
//                        AWS.objectMapper.save(item).continue({ (task: AWSTask<AnyObject>) -> Any? in
//                            return nil
//                        })
//                    }
//                    return nil
//                })
//            }
//            
//            return nil
//        })
        
//        AWS.test()
        if launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] != nil {
            #if CUSTOMER
                Api.push.openedWithNotification = true
            #endif
            // ignore merchant, since it's opening dashboard anyway
        }
        
//        let ignoredIds = ["909ee330-0e71-44c8-8cf7-9bf822d8c9f1", "486fb1af-aa54-40d6-a9ec-168ad4618dda", "68861adb-104a-4c8c-a2ef-ef562b5244cf", "8b85abbc-7856-42fd-9e5f-42b8ccc51492"]
//        AWS.objectMapper.scan(Order.self, expression: AWSDynamoDBScanExpression()).continue( { (task: AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
//            if let orders: [Order] = task.result?.items as! [Order]? {
//                for order in orders {
//                    if ignoredIds.contains(order.id) {
//                        continue
//                    }
//                    
//                    let migr: OrderMigration = OrderMigration()
//                    migr.merchantId = order.merchantId
//                    migr.id = order.id
//                    migr.number = order.number
//                    migr.tableNumber = order.tableNumber
//                    migr.typeNumber = order.typeNumber
//                    migr.dateTimeNumber = order.dateTimeNumber
//                    migr.customerUsername = order.customerUsername
//                    migr.customerName = order.customerName
//                    migr.customeriOSToken = order.customeriOsToken
//                    migr.customerAndroidToken = order.customerAndroidToken
//                    migr.basketJSONArrayString = order.basketJSONArrayString
//                    migr.isPaid = order.paid
//                    migr.isPickedUp = order.pickedUp
//                    migr.isCompleted = order.completed
//                    migr.isHiddenByCustomer = order.hiddenByCustomer
//                    migr.isHiddenByMerchant = order.hiddenByMerchant
//                    
//                    AWS.objectMapper.remove(order).continue({ (task: AWSTask<AnyObject>) -> Any? in
//                        if task.error != nil {
//                            AWS.objectMapper.save(migr).continue({ (task: AWSTask<AnyObject>) -> Any? in
//                                return nil
//                            })
//                        }
//                        return nil
//                    })
//                }
//            }
//            return nil
//        })
        
        return true
    }
    
    #if MERCHANT
    func launchPrinter(with order: Order) {
        let printer = Printer(order: order)
        
        printer.signal.observe(on: QueueScheduler.main).observe {
            if let error: Printer.PrinterError = $0.error {
                var message = ""
                
                switch error {
                case .couldntInit:
                    message = "Couldn't initialize printing"
                    break
                case .noBluetooth:
                    message = "Please turn on bluetooth to connect to the printer"
                    break
                case .noDeviceFound:
                    message = "No printers found"
                    break
                case .receiptNotCreated:
                    message = "Receipt couldn't be created"
                    break
                case .couldntConnect:
                    message = "Couldn't connect to the printer"
                    break
                case .printingUnavailable:
                    message = "Printing is unavailable"
                    break
                case .couldntPrint:
                    message = "Couldn't start printing"
                    break
                case .printerOffline:
                    message = "Printer is offline"
                    break
                case .printerNoResponse:
                    message = "Couldn't receive a response from the printer"
                    break
                case .printerCoverOpen:
                    message = "Please close roll paper cover"
                    break
                case .printerPaperFeed:
                    message = "Please release a paper feed switch"
                    break
                case .printerAutocutterNeedRecover:
                    message = "Please remove jammed paper and close roll paper cover.\nRemove any jammed paper or foreign substances in the printer, and then turn the printer off and turn the printer on again.\nThen, If the printer doesn\'t recover from error, please cycle the power switch."
                    break
                case .printerUnrecover:
                    message = "Please cycle the power switch of the printer.\nIf same errors occurred even power cycled, the printer may out of order."
                    break
                case .printerReceiptEnd:
                    message = "Please check roll paper"
                    break
                case .printerBatteryOverheat:
                    message = "Please wait until error LED of the printer turns off.\nBattery of printer is hot."
                    break
                case .printerHeadOverheat:
                    message = "Please wait until error LED of the printer turns off.\nPrint head of printer is hot."
                    break
                case .printerMotorOverheat:
                    message = "Please wait until error LED of the printer turns off.\nMotor Driver IC of printer is hot."
                    break
                case .printerWrongPaper:
                    message = "Please set correct roll paper"
                    break
                case .printerBatteryRealEnd:
                    message = "Please connect AC adapter or change the battery.\nBattery of printer is almost empty."
                    break
                    
                }
                
                UIAlertController.show(okAlertIn: Storyboard.appVC!,
                                       withTitle: "Printer failed",
                                       message: message)
            }
        }
        
        OperationQueue().addOperation {
            printer.start()
        }
    }
    
    #endif
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        if application.applicationState == .active {
            print("push notification userinfo = \(userInfo)")
            if let orderId: String = userInfo["id"] as! String?,
                let aps: [String:Any] = userInfo["aps"] as! [String:Any]?,
                let alert: String = aps["alert"] as! String? {
                #if MERCHANT
                    Api.orders.by(id: orderId)
                        .observe(on: QueueScheduler.main)
                        .observeValues {
                            if let order: Order = $0 {
                                Api.push.newOrderObserver.send(value: order)
                                
                                OrderNotification.show(order: order).observeValues {
                                    Storyboard.openHome()
                                }
                                
                                if Api.push.printingEnabled {
                                    self.launchPrinter(with: order)
                                }
                            }
                        }
                #endif
                #if CUSTOMER
                    if let merchantId: String = userInfo["merchant_id"] as! String? {
                        Api.orders.by(id: orderId, merchantId: merchantId)
                            .observe(on: QueueScheduler.main)
                            .observeValues {
                                if let order: Order = $0 {
                                    OrderNotification.show(order: order,
                                                           textFromRemoteNotification: alert)
                                        .observeValues {
                                            Storyboard.openOrderHistory()
                                        }
                                }
                            }
                    }
                #endif
            }
        } else {
            Api.push.openedWithNotification = true
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("PUSH received token \(deviceToken)")
        Api.push.token = deviceToken.hexRepresentation
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        print("PUSH registered for notification settings")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("PUSH did fail to register for push with error \(error)")
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        FBSDKAppEvents.activateApp()
        
        if let appVC: AppVC = Storyboard.appVC {
            if Api.push.openedWithNotification {
                Api.push.openedWithNotification = false
                #if MERCHANT
                    Storyboard.openHome()
                #endif
                #if CUSTOMER
                    Storyboard.openOrderHistory()
                #endif
            } else {
                #if MERCHANT
                    if appVC.navigationController?.viewControllers.last == appVC {
                        appVC.reload()
                    }
                #endif
            }
        }
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        AWSS3TransferUtility.interceptApplication(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
    }
}

