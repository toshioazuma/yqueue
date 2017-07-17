//
//  Merchants.swift
//  YQueue
//
//  Created by Toshio on 21/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import AWSDynamoDB
import ReactiveCocoa
import ReactiveSwift
import Result

class Merchants: NSObject {
    
    #if MERCHANT
    func auth(email: String) -> Signal<MerchantUser?, NoError> {
        let email = email.lowercased()
    
        let (signal, observer) = Signal<MerchantUser?, NoError>.pipe()
    
        AWS.objectMapper.load(MerchantUser.self, hashKey: email, rangeKey: nil).continue( { (task: AWSTask<AnyObject>) -> Any? in
            if let merchantUser: MerchantUser = task.result as! MerchantUser? {
                AWS.objectMapper.load(Merchant.self, hashKey: merchantUser.merchantId, rangeKey: nil).continue( { (task: AWSTask<AnyObject>) -> Any? in
                    if let merchant: Merchant = task.result as! Merchant? {
                        merchantUser.merchant = merchant
                        observer.send(value: merchantUser)
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
//        expr.expressionAttributeValues = [":merchantId" = ]
    
//        let expr = AWSDynamoDBScanExpression()
//        expr.filterExpression = "#owner = :email"
//        expr.expressionAttributeNames = ["#owner":"owner"]
//        expr.expressionAttributeValues = [":email":email]
//        
//        AWS.objectMapper.scan(Merchant.self, expression: expr)
//            .continue({ (task: AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
//            let merchant = task.error == nil && (task.result?.items.count)! > 0 ? task.result?.items.first! : nil
//            print("owner email \(email) error = \(task.error) result = \(task.result)")
//            if let merchant: Merchant = merchant as! Merchant? {
//                observer.send(value: (merchant, .owner))
//            } else {
//                let expr = AWSDynamoDBScanExpression()
//                expr.filterExpression = "contains(#users, :email)"
//                expr.expressionAttributeNames = ["#users":"users"]
//                expr.expressionAttributeValues = [":email":email]
//                
//                AWS.objectMapper.scan(Merchant.self, expression: expr)
//                    .continue({ (task: AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
//                    let merchant = task.error == nil && (task.result?.items.count)! > 0
//                        ? task.result?.items.first! : nil
//                    print("employee email = \(email) error = \(task.error) result = \(task.result)")
//                    if task.error != nil {
//                        observer.send(value: nil)
//                    } else if let merchant: Merchant = merchant as! Merchant? {
//                        observer.send(value: (merchant, .user))
//                    }
//                    
//                    return nil
//                })
//            }
//            
//            return nil
//        })
    
        return signal
    }
    
    func editRestaurant(title: String, workingFrom: Int, workingTo: Int, gst: Double, tax: Double, takeAwayAvailable: Bool, dineInAvailable: Bool) -> Signal<Bool, NoError> {
        let (signal, observer) = Signal<Bool, NoError>.pipe()
        
        let merchant: Merchant = Api.auth.merchantUser.merchant
        merchant.title = title
        merchant.workingFrom = workingFrom
        merchant.workingTo = workingTo
        merchant.gst = gst
        merchant.tax = tax
        merchant.isTakeAwayAvailable = takeAwayAvailable
        merchant.isDineInAvailable = dineInAvailable
        
        AWS.objectMapper.save(merchant).continue( { (task: AWSTask<AnyObject>) -> Any? in
            observer.send(value: task.error == nil)
        })
        
        return signal
    }
    #endif
    
    #if CUSTOMER
    
    
    func list(in region: MKCoordinateRegion) -> Signal<[Merchant], NoError> {
        let (signal, observer) = Signal<[Merchant], NoError>.pipe()
        
        let filterModeString = "and \(Storyboard.dineIn! ? "dineInAvailable" : "takeAwayAvailable") = :modeValue"
        
        let expr = AWSDynamoDBScanExpression()
        expr.filterExpression = "latitude >= :minLatitude and latitude <= :maxLatitude and longitude >= :minLongitude and longitude <= :maxLongitude"// ".appending(filterModeString)
        expr.expressionAttributeValues = [
            ":minLatitude" : region.center.latitude-region.span.latitudeDelta,
            ":maxLatitude" : region.center.latitude+region.span.latitudeDelta,
            ":minLongitude" : region.center.longitude-region.span.longitudeDelta,
            ":maxLongitude" : region.center.longitude+region.span.longitudeDelta,
            //":modeValue" : 1
        ]
        
        AWS.objectMapper.scan(Merchant.self, expression: expr)
            .continue({ (task: AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
                var merchants = [Merchant]()
                if task.error == nil {
                    merchants.append(contentsOf: (task.result?.items as! [Merchant]))
                }
                
                observer.send(value: merchants)
                
                return nil
            })
        
        return signal
    }
    
    func list(in ids: [String]) -> Signal<[String:Merchant], NoError> {
        let (signal, observer) = Signal<[String:Merchant], NoError>.pipe()
    
        if ids.count == 0 {
            OperationQueue.main.addOperation {
                observer.send(value: [:])
            }
        } else {
            let id = ids[0]
            
            let expr = AWSDynamoDBQueryExpression()
            expr.keyConditionExpression = "id = :id"
            expr.expressionAttributeValues = [":id":id]
            
            AWS.objectMapper.query(Merchant.self, expression: expr)
                .continue({ (task: AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
                    var merchants = [String:Merchant]()
                    if task.error == nil,
                        let merchant: Merchant = task.result?.items[0] as! Merchant? {
                        print("received merchant with id \(id)")
                        merchants[id] = merchant
                    }
                    
                    var ids = ids
                    ids.removeFirst()
                    print("merchant ids left = \(ids)")
                    
                    if ids.count == 0 {
                        print("ids now empty, send observer")
                        observer.send(value: merchants)
                    } else {
                        print("still have some ids, query further")
                        self.list(in: ids).observeValues {
                            print("received \($0.count) merchants")
                            for (id, merchant) in $0 {
                                print("therefore setting merchant with id \(id) to current dictionary")
                                merchants[id] = merchant
                            }
                            print("finally received merchants = \(merchants)")
                            
                            observer.send(value: merchants)
                        }
                    }
                    
                    return nil
                })
        }
        
        return signal
    }
    
    #endif
}
