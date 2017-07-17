//
//  MerchantFeedbackVM.swift
//  YQueue
//
//  Created by Toshio on 28/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantFeedbackVM: NSObject, ModelTableViewCellModelProtocol {
    
    var selected = MutableProperty(false)
    
    var order: Order
    var orderFeedback: OrderFeedback
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? {
        get {
            if selected.value {
                if orderFeedback.ambience == 0 {
                    return "ItemSelectedNoAmbience"
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
                return nil
            }
            
            return 60.0
        } set {
            
        }
    }
    var estimatedRowHeight: CGFloat? {
        get {
            if selected.value {
                if orderFeedback.ambience == 0 {
                    return 245
                } else {
                    return 285
                }
            }
            
            return nil
        } set {
            
        }
    }
    var tableView: ModelTableView!
    
    init(orderFeedback: OrderFeedback) {
        order = orderFeedback.order
        self.orderFeedback = orderFeedback
        super.init()
    }
    
    func modelBound() {
    }
}
