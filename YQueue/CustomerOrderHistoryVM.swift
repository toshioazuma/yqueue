//
//  CustomerOrderHistoryVM.swift
//  YQueue
//
//  Created by Toshio on 08/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerOrderHistoryVM: NSObject, ModelTableViewCellModelProtocol {
    
    var orderTableViewHeight = MutableProperty<CGFloat>(0.0)
    var selected = MutableProperty(false)
    
    var order: Order
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? {
        get {
            if selected.value {
                if order.isFeedbackSent {
                    return "ItemSelectedNoFeedback"
                } else {
                    return "ItemSelected"
                }
            } else {
                return "Item"
            }
        } set {
            
        }
    }
    var rowHeight: CGFloat? {
        get {
            if selected.value {
                if order.isFeedbackSent {
                    let heightWithoutTable: CGFloat = 183.0
                    return heightWithoutTable + orderTableViewHeight.value
                } else {
                    let heightWithoutTable: CGFloat = 242.0
                    return heightWithoutTable + orderTableViewHeight.value
                }
            }
            
            return 60.0
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
