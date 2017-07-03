//
//  MerchantEditMenuTagsVM.swift
//  YQueue
//
//  Created by Aleksandr on 25/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantEditMenuTagsVM: NSObject, ModelTableViewCellModelProtocol {
    
    var bestSelling = MutableProperty(false)
    var chefsSpecial = MutableProperty(false)
    var glutenFree = MutableProperty(false)
    var vegeterian = MutableProperty(false)
    
    var menuItem: MenuItem?
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = "Tags"
    var rowHeight: CGFloat? = 165
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    init(menuItem: MenuItem?) {
        self.menuItem = menuItem
        
        if let menuItem: MenuItem = menuItem {
            bestSelling.consume(menuItem.isBestSelling)
            chefsSpecial.consume(menuItem.isChefsSpecial)
            glutenFree.consume(menuItem.isGlutenFree)
            vegeterian.consume(menuItem.isVegeterian)
        }
        
        super.init()
    }
    
    func modelBound() {
        if let menuItem: MenuItem = menuItem {
            bestSelling.consume(menuItem.isBestSelling)
            chefsSpecial.consume(menuItem.isChefsSpecial)
            glutenFree.consume(menuItem.isGlutenFree)
            vegeterian.consume(menuItem.isVegeterian)
        } else {
            bestSelling.consumeCurrent()
            chefsSpecial.consumeCurrent()
            glutenFree.consumeCurrent()
            vegeterian.consumeCurrent()
        }
    }
}
