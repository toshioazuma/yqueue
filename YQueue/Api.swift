//
//  Api.swift
//  YQueue
//
//  Created by Toshio on 03/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit

class Api: NSObject {
    
    static let auth = Authorization()
    static let merchants = Merchants()
    static let menuCategories = MenuCategories()
    static let menuItems = MenuItems()
    static let orders = Orders()
    static let push = Push()
    
    #if CUSTOMER
    static let paymentGateway = PaymentGateway()
    #endif
}
