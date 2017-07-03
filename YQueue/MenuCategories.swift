//
//  MenuCategories.swift
//  YQueue
//
//  Created by Aleksandr on 21/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import AWSDynamoDB
import ReactiveCocoa
import ReactiveSwift
import Result

class MenuCategories: NSObject {
    
    func list(for merchant: Merchant) -> Signal<[MenuCategory]?, NoError> {
        let (signal, observer) = Signal<[MenuCategory]?, NoError>.pipe()

        let expr = AWSDynamoDBQueryExpression()
        expr.keyConditionExpression = "merchantId = :merchantId"
        expr.expressionAttributeValues = [":merchantId":merchant.id]
        
        AWS.objectMapper.query(MenuCategory.self, expression: expr)
            .continue( { (task: AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
                if task.error != nil {
                    observer.send(value: nil)
                    return nil
                }
                
                var menuCategories = Array<MenuCategory>()
                if task.error == nil {
                    for menuCategory: MenuCategory in task.result?.items as! [MenuCategory] {
                        menuCategory.merchant = merchant
                        menuCategories.append(menuCategory)
                    }
                }
                merchant.menuCategories = menuCategories
                observer.send(value: menuCategories)
                
                return nil
        })
        
        return signal
    }
    
    #if MERCHANT
    
    func addMenuCategory(_ menuCategory: MenuCategory) -> Signal<Bool, NoError> {
        let (signal, observer) = Signal<Bool, NoError>.pipe()
        
        menuCategory.id = UUID().uuidString.lowercased()
        menuCategory.merchantId = Api.auth.merchantUser.merchant.id
        menuCategory.merchant = Api.auth.merchantUser.merchant
        
        if menuCategory.position < 1 {
            menuCategory.position = 1
        }
        
        let query = AWSDynamoDBQueryExpression()
        query.keyConditionExpression = "merchantId = :merchantId"
        query.expressionAttributeValues = [":merchantId" : menuCategory.merchantId]
        
        AWS.objectMapper.query(MenuCategory.self, expression: query).continue({ (task: AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
            if var menuCategories: [MenuCategory] = task.result?.items as! [MenuCategory]? {
                menuCategories.sort(by: { (lhs: MenuCategory, rhs: MenuCategory) -> Bool in
                    return rhs.position > lhs.position
                })
                
                // fix position if exceeds count
                if menuCategory.position > menuCategories.count+1 {
                    menuCategory.position = menuCategories.count+1
                }
                
                // now insert menu category at desired position
                menuCategories.insert(menuCategory, at: menuCategory.position-1)
                
                // now set up new positions
                for (i, mc) in menuCategories.enumerated() {
                    mc.position = i+1
                    
                    AWS.objectMapper.save(mc).continue({ (task: AWSTask<AnyObject>) -> Any? in
                        return nil
                    })
                }
                
                observer.send(value: true)
                
                Api.auth.merchantUser.merchant.menuCategories = menuCategories
            }
            
            return nil
        })
        
        
//        Api.auth.merchant.menuCategories?.append(menuCategory)
//        
//        AWS.objectMapper.save(menuCategory).continue( { (task: AWSTask<AnyObject>) -> Any? in
//            observer.send(value: task.error == nil)
//        })
        
        return signal
    }
    
    func change(_ menuCategory: MenuCategory, title: String, position: Int) -> Signal<Bool, NoError> {
        let (signal, observer) = Signal<Bool, NoError>.pipe()
        
        var position = position
        if position < 1 {
            position = 1
        }
        
        let oldTitle = menuCategory.title
        menuCategory.title = title
        let oldPosition = menuCategory.position
        menuCategory.position = position
        
//        if oldPosition == position {
//            AWS.objectMapper.save(menuCategory).continue( { (task: AWSTask<AnyObject>) -> Any? in
//                if task.error != nil {
//                    menuCategory.title = oldTitle
//                    menuCategory.position = oldPosition
//                }
//                observer.send(value: task.error == nil)
//                
//                return nil
//            })
//        } else {
            let query = AWSDynamoDBQueryExpression()
            query.keyConditionExpression = "merchantId = :merchantId"
            query.expressionAttributeValues = [":merchantId" : menuCategory.merchantId]
            
            AWS.objectMapper.query(MenuCategory.self, expression: query).continue({ (task: AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
                if var menuCategories: [MenuCategory] = task.result?.items as! [MenuCategory]? {
                    menuCategories.sort(by: { (lhs: MenuCategory, rhs: MenuCategory) -> Bool in
                        return rhs.position > lhs.position
                    })
                    
                    // fix position if exceeds count
                    if menuCategory.position > menuCategories.count {
                        menuCategory.position = menuCategories.count
                    }
                    
                    // remove menu category from list
                    menuCategories = menuCategories.filter { $0.id != menuCategory.id }
                    
                    // now insert menu category at desired position
                    menuCategories.insert(menuCategory, at: menuCategory.position-1)
                    
                    // now set up new positions
                    for (i, mc) in menuCategories.enumerated() {
                        mc.position = i+1
                        
                        AWS.objectMapper.save(mc).continue({ (task: AWSTask<AnyObject>) -> Any? in
                            return nil
                        })
                    }
                    
                    Api.auth.merchantUser.merchant.menuCategories = menuCategories
                    observer.send(value: true)
                } else {
                    menuCategory.title = oldTitle
                    menuCategory.position = oldPosition
                    observer.send(value: false)
                }
                return nil
            })
//        }
        
        return signal
        
    }
    
    func delete(_ menuCategory: MenuCategory, menuItems: [MenuItem]) -> Signal<Bool, NoError> {
        let (signal, observer) = Signal<Bool, NoError>.pipe()
        
        Api.auth.merchantUser.merchant.menuCategories = Api.auth.merchantUser.merchant.menuCategories
            .filter { $0 != menuCategory }
        
        AWS.objectMapper.remove(menuCategory).continue( { (task: AWSTask<AnyObject>) -> Any? in
            if task.error == nil {
                for menuItem in menuItems {
                    AWS.objectMapper.remove(menuItem).continue({ _ in return nil })
                }
            }
            
            observer.send(value: task.error == nil)
            
            return nil
        })
        
        return signal
    }
    
    #endif
}
