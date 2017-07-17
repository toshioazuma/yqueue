//
//  MerchantEditMenuDataVM.swift
//  YQueue
//
//  Created by Toshio on 25/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantEditMenuDataVM: NSObject, ModelTableViewCellModelProtocol {
    
    var name = MutableProperty("")
    var number = MutableProperty("")
    var price = MutableProperty(0.0)
    var descriptionText = MutableProperty("")
    var specialOfferText = MutableProperty("")
    var menuCategory = MutableProperty<MenuCategory?>(nil)
    
    var menuItem: MenuItem?
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = "Data"
    var rowHeight: CGFloat? = 460
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    init(menuItem: MenuItem?) {
        self.menuItem = menuItem
        super.init()
    }
    
    func modelBound() {
        if let menuItem: MenuItem = menuItem {
            name.consume(menuItem.name)
            number.consume(menuItem.number)
            price.consume(menuItem.price)
            descriptionText.consume(menuItem.descriptionText.aws)
            specialOfferText.consume(menuItem.specialOfferText.aws)
            menuCategory.consume(menuItem.category)
        } else {
            name.consumeCurrent()
            number.consumeCurrent()
            descriptionText.consumeCurrent()
            specialOfferText.consumeCurrent()
        }
    }
}
