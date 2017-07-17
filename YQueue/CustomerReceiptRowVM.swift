//
//  CustomerReceiptRowVM.swift
//  YQueue
//
//  Created by Toshio on 07/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerReceiptRowVM: NSObject, ModelTableViewCellModelProtocol {
    
    static func item(_ item: Basket.Item) -> CustomerReceiptRowVM {
        let vm = CustomerReceiptRowVM()
        
        if let option: MenuItem.Option = item.option {
            vm.reuseIdentifier = "OrderListItemWithOption"
            vm.estimatedRowHeight = 36
            vm.subTitle.consume(option.name)
        } else {
            vm.reuseIdentifier = "OrderListItem"
            vm.estimatedRowHeight = 21
        }
        
        vm.title.consume("\(item.count) \(item.menuItem.name)")
        vm.price.consume(item.totalPrice)
        
        return vm
    }
    
    static func gst(basket: Basket, merchant: Merchant) -> CustomerReceiptRowVM {
        let vm = CustomerReceiptRowVM()
        vm.reuseIdentifier = "Gst"
        vm.rowHeight = 21
        
        let total = basket.items.map{ $0.totalPrice }.reduce(0, +)
        
        vm.title.consume("GST Included")
        vm.price.consume(total * merchant.gst / 100.0)
        
        return vm
    }
    
    static func tax(basket: Basket, merchant: Merchant) -> CustomerReceiptRowVM {
        let vm = CustomerReceiptRowVM()
        vm.reuseIdentifier = "Tax"
        vm.rowHeight = 21
        
        let total = basket.items.map{ $0.totalPrice }.reduce(0, +)
        
        vm.title.consume("Tax Included")
        vm.price.consume(total * merchant.tax / 100.0)
        
        return vm
    }
    
    static func total(basket: Basket, merchant: Merchant) -> CustomerReceiptRowVM {
        let vm = CustomerReceiptRowVM()
        vm.reuseIdentifier = "Total"
        vm.rowHeight = 31
        
        let total = basket.items.map{ $0.totalPrice }.reduce(0, +)
        let tax = total * merchant.tax / 100.0
        let grandTotal = round((total+tax) * 100.0) / 100.0
        
        vm.title.consume("Total")
        vm.price.consume(grandTotal)
        
        return vm
    }
    
    var title = MutableProperty("")
    var subTitle = MutableProperty("")
    var price = MutableProperty(0.0)
    
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String?
    var rowHeight: CGFloat?
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    func modelBound() {
    }
}
