//
//  CustomerSlipVM.swift
//  YQueue
//
//  Created by Aleksandr on 30/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerSlipVM: NSObject, ModelTableViewCellModelProtocol {
    
    var count = MutableProperty(0)
    var offset = MutableProperty<CGFloat>(0)
    
    var item: Basket.Item?
    var merchant: Merchant!
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = nil
    var rowHeight: CGFloat?
    var estimatedRowHeight: CGFloat? = 69
    var tableView: ModelTableView!
    var offsetCallback: ((CGFloat) -> Void)!
    
    init(item: Basket.Item, offsetCallback: @escaping (CGFloat) -> Void) {
        self.item = item
        self.merchant = item.menuItem.category.merchant
        self.offsetCallback = offsetCallback
        super.init()
        
        offset.signal.observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.offsetCallback($0)
        }
    }
    
    init(merchant: Merchant) {
        self.merchant = merchant
        super.init()
    }
    
    func modelBound() {
        if let item: Basket.Item = item {
            count.consume(item.count)
        }
    }
}
