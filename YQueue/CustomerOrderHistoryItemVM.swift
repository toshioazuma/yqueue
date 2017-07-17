//
//  CustomerOrderHistoryItemVM.swift
//  YQueue
//
//  Created by Toshio on 15/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerOrderHistoryItemVM: NSObject, ModelTableViewCellModelProtocol {
    
    var name = MutableProperty("")
    var option = MutableProperty("")
    var price = MutableProperty(0.0)
    
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? {
        get {
            return option.value == "" ? "Item" : "ItemWithOption"
        } set {
            
        }
    }
    var rowHeight: CGFloat?
    var estimatedRowHeight: CGFloat? {
        get {
            return option.value == "" ? 21 : 36
        } set {
            
        }
    }
    var tableView: ModelTableView!
    
    init(item: Basket.Item) {
        name.consume("\(item.count) \(item.menuItem.name)")
        price.consume(item.totalPrice)
        if let option: MenuItem.Option = item.option {
            self.option.consume(option.name)
        }
        super.init()
    }
    
    func modelBound() {
    }
}
