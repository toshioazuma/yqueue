//
//  MerchantEditMenuOptionVM.swift
//  YQueue
//
//  Created by Toshio on 25/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantEditMenuOptionVM: NSObject, ModelTableViewCellModelProtocol {
    
    var id = MutableProperty("")
    var name = MutableProperty("")
    var price = MutableProperty(0.0)
    
    var option: MenuItem.Option
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = "Option"
    var rowHeight: CGFloat? = 54
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    init(option: MenuItem.Option) {
        self.option = option
        super.init()
        
        // sign for changes, so if another option is added, its value is saved on table view reload
        name.signal.observeValues {
            option.name = $0
        }
        price.signal.observeValues {
            option.price = $0
        }
    }
    
    func modelBound() {
        id.consume(option.id)
        name.consume(option.name)
        price.consume(option.price)
    }
}
