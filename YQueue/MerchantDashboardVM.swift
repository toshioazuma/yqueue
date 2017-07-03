//
//  MerchantDashboardVM.swift
//  YQueue
//
//  Created by Aleksandr on 15/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantDashboardVM: NSObject, ModelTableViewCellModelProtocol {
    
    var orderTableViewHeight = MutableProperty<CGFloat>(0.0)
    var selected = MutableProperty(false)
    
    var order: Order
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? {
        get {
            return selected.value ? "ItemSelected" : "Item"
        } set {
            
        }
    }
    var rowHeight: CGFloat? {
        get {
            if selected.value {
                let heightWithoutTable: CGFloat = 242.0
                return heightWithoutTable + orderTableViewHeight.value
            }
            return selected.value ? nil : 60.0
        } set {
            
        }
    }
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    init(order: Order) {
        self.order = order
        super.init()
    }
    
    func modelBound() {
        
    }
}
