//
//  MerchantEditMenuCategoryAlertVM.swift
//  YQueue
//
//  Created by Aleksandr on 25/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantEditMenuCategoryAlertVM: NSObject, ModelTableViewCellModelProtocol {
    
    var menuCategory: MenuCategory?
    var selected = MutableProperty(false)
    var tapSignal: Signal<Void, NoError>
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = nil
    var rowHeight: CGFloat? = 40
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    init(menuCategory: MenuCategory?, tap: @escaping () -> Void) {
        self.menuCategory = menuCategory
        
        let (tapSignal, tapObserver) = Signal<Void, NoError>.pipe()
        tapSignal.observe { _ in
            tap()
        }
    
        self.tapSignal = tapSignal
        self.tapObserver = tapObserver
        
        super.init()
    }
    
    func modelBound() {
    }
}
