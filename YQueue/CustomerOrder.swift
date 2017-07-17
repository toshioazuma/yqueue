//
//  CustomerOrder.swift
//  YQueue
//
//  Created by Toshio on 06/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit

class CustomerOrder: NSObject {

    var id: String
    var name: String
    var type: String
    var count: Int
    var price: Double
    
    init(id: String, name: String, type: String, count: Int, price: Double) {
        self.id = id
        self.name = name
        self.type = type
        self.count = count
        self.price = price
        
        super.init()
    }
    
    public static func testData() -> Array<CustomerOrder> {
        let ids = ["C001","C002","C003","C201","C202","C203","C301","C302","C304"]
        let names = ["Neapolitan Pizza", "Sicilian Pizza", "Tomato Pie Pizza", "Coke", "Orange Juice", "Lemon Juice", "Neapolitan Pizza", "Sicilian Pizza", "Medium Portion"]
        let types = ["Marinara Type", "Small Portion", "Medium Portion", "500ml", "Small Portion", "Small Portion", "Marinara Type", "Small Portion", "Medium Portion"]
        let counts = [3,1,3,1,3,1,3,1,3]
        let prices = [49.99,49.99,49.99,1.97,5.00,4.97,49.99,49.99,49.99]
    
        var orders = Array<CustomerOrder>()
        for i in 0...8 {
            orders.append(CustomerOrder.init(id: ids[i], name: names[i], type: types[i], count: counts[i], price: prices[i]))
        }
        
        return orders
    }
}
