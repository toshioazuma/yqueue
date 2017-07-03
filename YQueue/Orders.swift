//
//  Orders.swift
//  YQueue
//
//  Created by Aleksandr on 15/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import AWSDynamoDB
import AWSS3
import ReactiveCocoa
import ReactiveSwift
import Result

class Orders: NSObject {
    
    #if CUSTOMER
    
    func post(feedback: OrderFeedback, for order: Order) -> Signal<Bool, NoError> {
        let (signal, observer) = Signal<Bool, NoError>.pipe()
        
        feedback.merchant = order.merchant
        feedback.order = order
        feedback.dateTime = Date()
        feedback.prepareForSave()
    
        AWS.objectMapper.save(feedback).continue( { (task: AWSTask<AnyObject>) -> Any? in
            if task.error != nil {
                observer.send(value: false)
            } else {
                order.isFeedbackSent = true
                AWS.objectMapper.save(order).continue({ (task: AWSTask<AnyObject>) -> Any? in
                    observer.send(value: task.error == nil)
                })
            }
            return nil
        })
        
        return signal
    }
    
    func list() -> Signal<[Order]?, NoError> {
        let (signal, observer) = Signal<[Order]?, NoError>.pipe()
        
        let expr = AWSDynamoDBQueryExpression()
        expr.indexName = "customerUsername-index"
        expr.scanIndexForward = NSNumber(booleanLiteral: true)
        expr.keyConditionExpression = "customerUsername = :customerUsername"
        expr.filterExpression = "paid = :paid and hiddenByCustomer = :hiddenByCustomer"
        expr.expressionAttributeValues = [":customerUsername" : Api.auth.username!,
                                          ":paid" : 1,
                                          ":hiddenByCustomer" : 0]
        
        AWS.objectMapper.query(Order.self, expression: expr).continue( { (task: AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
            if task.error != nil {
                observer.send(value: nil)
            } else {
                var orders = Array<Order>()
                var merchantIds = [String]()
                for order: Order in task.result?.items as! [Order] {
                    orders.append(order)
                    
                    if !merchantIds.contains(order.merchantId) {
                        merchantIds.append(order.merchantId)
                    }
                }
                print("loaded orders with merchant ids = \(merchantIds)")
                if merchantIds.count > 0 {
                    Api.merchants.list(in: merchantIds).observeValues {
                        for order in orders {
                            if let merchant: Merchant = $0[order.merchantId] {
                                print("Assigning merchant \(merchant.title) to order with id \(order.id)")
                                order.merchant = merchant
                            } else {
                                observer.send(value: nil)
                            }
                        }
                        
                        observer.send(value: orders)
                    }
                } else {
                    observer.send(value: orders)
                }
            }
            
            return nil
        })
        
        return signal
    }
    
    func place(_ order: Order) -> Signal<Bool, NoError> {
        let (signal, observer) = Signal<Bool, NoError>.pipe()
        
        if let pushToken: String = Api.push.token {
            order.customeriOsToken = pushToken
        }
        
        AWS.objectMapper.save(order).continue( { (task: AWSTask<AnyObject>) -> Any? in
            if task.error != nil {
                observer.send(value: false)
            } else {
                self.suggestNumber(for: order).observeValues {
                    order.number = $0
                    
                    AWS.objectMapper.save(order).continue({ (task: AWSTask<AnyObject>) -> Any? in
                        observer.send(value: task.error == nil)
                        
                        return nil
                    })
                }
            }
    
            return nil
        })
        
        return signal
    }
    
    private func suggestNumber(for order: Order) -> Signal<Int, NoError> {
        let (signal, observer) = Signal<Int, NoError>.pipe()
        
        let merchantIdValue: AWSDynamoDBAttributeValue = AWSDynamoDBAttributeValue()
        merchantIdValue.s = order.merchantId
        print("order date time number = \(String(format: "%f", order.dateTimeNumber))")
        let dateTimeNumberValue: AWSDynamoDBAttributeValue = AWSDynamoDBAttributeValue()
        dateTimeNumberValue.n = String(format: "%f", order.dateTimeNumber)
        print("order date time number in value = \(String(format: "%f", dateTimeNumberValue.n!))")
        
        let input: AWSDynamoDBQueryInput = AWSDynamoDBQueryInput()
        input.tableName = "Orders"
        input.keyConditionExpression = "merchantId = :merchantId"
        input.filterExpression = "dateTimeNumber < :dateTimeNumber"
        input.expressionAttributeValues = [":merchantId" : merchantIdValue,
                                           ":dateTimeNumber" : dateTimeNumberValue]
        input.select = AWSDynamoDBSelect.count
        
        AWS.dynamoDB.query(input).continue({ (task: AWSTask<AWSDynamoDBQueryOutput>) -> Any? in
            if let result: AWSDynamoDBQueryOutput = task.result,
                let count: NSNumber = result.count,
                let scannedCount: NSNumber = result.scannedCount {
                
                if count.intValue == scannedCount.intValue {
                    // This can't be true, since our date time is much greater than query's top
                    // Try again until order is stored
                    self.suggestNumber(for: order).observeValues {
                        observer.send(value: $0)
                    }
                } else {
                    observer.send(value: count.intValue + 1)
                }
            } else {
                self.suggestNumber(for: order).observeValues {
                    observer.send(value: $0)
                }
            }
            
            return nil
        })
        
        return signal
    }
    
    func pay(_ order: Order) -> Signal<Bool, NoError> {
        let (signal, observer) = Signal<Bool, NoError>.pipe()
        
        order.isPaid = true
        AWS.objectMapper.save(order).continue( { (task: AWSTask<AnyObject>) -> Any? in
            if task.error != nil {
                order.isPaid = false
            } else {
                Api.push.paid(order: order)
                
                if let email: String = Api.auth.email,
                    email.isValidEmail {
                    
                    var orderStringObjects = [String]()
                    for item in order.basket.items {
                        var stringObject = "\(item.count) \(item.menuItem.name)"
                        if let option: MenuItem.Option = item.option {
                            stringObject = stringObject
                                .appending(" - ")
                                .appending(option.name)
                                .appending(" $")
                                .appending(item.totalPrice.format(precision: 2,
                                                                  ignorePrecisionIfRounded: true))
                        }
                        orderStringObjects.append(stringObject)
                    }
                    
                    let total = order.basket.items.map{ $0.totalPrice }.reduce(0, +)
                    let tax = total * order.merchant.tax / 100.0
                    let gst = total * order.merchant.gst / 100.0
                    let messageObjects = ["Type: ".appending(order.type == .takeAway ? "Take Away Order" : "Dine In Order\nTable no. ".appending(order.tableNumber)),
                                          "Order List: \n".appending(orderStringObjects.joined(separator: "\n")),
                                          "\nGST Included: $".appending(gst.format(precision: 2, ignorePrecisionIfRounded: true)),
                                          "Tax Included: $".appending(tax.format(precision: 2, ignorePrecisionIfRounded: true)),
                                          "\nTotal: $".appending(order.totalPriceWithTax.format(precision: 2, ignorePrecisionIfRounded: true))]
                    let message = messageObjects.joined(separator: "\n")
                    
                    AWS.send(emailTo: email,
                             subject: "YQueue: Order #\(order.merchant.number)-\(order.number)",
                             body: "\(Api.auth.name!),\n\nWe have successfully received your order for \(order.merchant.title!).\n\n\(message)\n\nYQueue Team.")
                }
            }
            
            observer.send(value: task.error == nil)
            
            return nil
        })
        
        return signal
    }
    
    func by(id: String, merchantId: String) -> Signal<Order?, NoError> {
        let (signal, observer) = Signal<Order?, NoError>.pipe()
        
        AWS.objectMapper.load(Merchant.self, hashKey: merchantId, rangeKey: nil).continue( { (task: AWSTask<AnyObject>) -> Any? in
            if let merchant: Merchant = task.result as! Merchant? {
                AWS.objectMapper.load(Order.self, hashKey: merchantId, rangeKey: id).continue( { (task: AWSTask<AnyObject>) -> Any? in
                    if let order: Order = task.result as! Order? {
                        order.merchant = merchant
                        observer.send(value: order)
                    } else {
                        observer.send(value: nil)
                    }
                    
                    return nil
                })
            } else {
                observer.send(value: nil)
            }
            
            return nil
        })
        
        return signal
    }
    
    #endif
    
    #if MERCHANT
    
    func by(id: String) -> Signal<Order?, NoError> {
        let (signal, observer) = Signal<Order?, NoError>.pipe()
        
        AWS.objectMapper.load(Order.self, hashKey: Api.auth.merchantUser.merchant.id, rangeKey: id).continue( { (task: AWSTask<AnyObject>) -> Any? in
            if let result: Order = task.result as! Order? {
                result.merchant = Api.auth.merchantUser.merchant
                observer.send(value: result)
            } else {
                observer.send(value: nil)
            }
            
            return nil
        })
        
        return signal
    }
    
    func listFeedback() -> Signal<[OrderFeedback]?, NoError> {
        let (signal, observer) = Signal<[OrderFeedback]?, NoError>.pipe()
        
        let expr = AWSDynamoDBQueryExpression()
        expr.keyConditionExpression = "merchantId = :merchantId"
        expr.expressionAttributeValues = [":merchantId" : Api.auth.merchantUser.merchant.id]
        
        AWS.objectMapper.query(OrderFeedback.self, expression: expr).continue( { (task: AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
            if let ordersFeedback: [OrderFeedback] = task.result?.items as! [OrderFeedback]? {
                if ordersFeedback.count == 0 {
                    observer.send(value: [])
                    return nil
                }
                
                OperationQueue().addOperation {
                    for orderFeedback in ordersFeedback {
                        orderFeedback.merchant = Api.auth.merchantUser.merchant
                        AWS.objectMapper.load(Order.self, hashKey: orderFeedback.merchantId, rangeKey: orderFeedback.id).continue({ (task: AWSTask<AnyObject>) -> Any? in
                            if let order: Order = task.result as! Order? {
                                order.merchant = Api.auth.merchantUser.merchant
                                orderFeedback.order = order
                            }
                            return nil
                        }).waitUntilFinished()
                    }
                    
                    observer.send(value: ordersFeedback)
                }
            } else {
                observer.send(value: nil)
            }
            
            return nil
        })

        return signal
    }
    
    func list() -> Signal<[Order]?, NoError> {
        let (signal, observer) = Signal<[Order]?, NoError>.pipe()
    
        let expr = AWSDynamoDBQueryExpression()
        expr.keyConditionExpression = "merchantId = :merchantId"
        expr.filterExpression = "paid = :paid and hiddenByMerchant = :hiddenByMerchant"
        expr.expressionAttributeValues = [":merchantId" : Api.auth.merchantUser.merchant.id,
                                          ":paid" : 1,
                                          ":hiddenByMerchant" : 0]
        
        AWS.objectMapper.query(Order.self, expression: expr).continue( { (task: AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
            if let orders: [Order] = task.result?.items as! [Order]? {
                for order: Order in orders {
                    order.merchant = Api.auth.merchantUser.merchant
                }
                
                observer.send(value: orders)
            } else {
                observer.send(value: nil)
            }
            
            return nil
        })
    
        return signal
    }
    
    func pickUp(_ order: Order) -> Signal<Bool, NoError> {
        let (signal, observer) = Signal<Bool, NoError>.pipe()
        
        order.isPickedUp = true
        AWS.objectMapper.save(order).continue( { (task: AWSTask<AnyObject>) -> Any? in
            if task.error != nil {
                order.isPickedUp = false
            } else {
                Api.push.pickedUp(order: order)
            }
            
            observer.send(value: task.error == nil)
            
            return nil
        })
        
        return signal
    }
    
    func completed(_ order: Order) -> Signal<Bool, NoError> {
        let (signal, observer) = Signal<Bool, NoError>.pipe()
        
        order.isCompleted = true
        AWS.objectMapper.save(order).continue( { (task: AWSTask<AnyObject>) -> Any? in
            if task.error != nil {
                order.isCompleted = false
            } else {
                Api.push.completed(order: order)
            }
            
            observer.send(value: task.error == nil)
            
            return nil
        })
        
        return signal
    }
    
    func hide(_ order: Order) -> Signal<Bool, NoError> {
        let (signal, observer) = Signal<Bool, NoError>.pipe()
        
        order.isHiddenByMerchant = true
        AWS.objectMapper.save(order).continue( { (task: AWSTask<AnyObject>) -> Any? in
            if task.error != nil {
                order.isHiddenByMerchant = false
            }
            
//            observer.send(value: false)
            observer.send(value: task.error == nil)
            
            return nil
        })
        
        return signal
    }
    
    #endif
}
