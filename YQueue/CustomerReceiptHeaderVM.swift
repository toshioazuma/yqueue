//
//  CustomerReceiptHeaderVM.swift
//  YQueue
//
//  Created by Toshio on 07/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerReceiptHeaderVM: NSObject, ModelTableViewCellModelProtocol {
    
    var merchant: Merchant
    var order: Order
    
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = "Header"
    var rowHeight: CGFloat? = 80
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    init(merchant: Merchant, order: Order) {
        self.merchant = merchant
        self.order = order
        super.init()
    }
    
    func modelBound() {
    }
}
