//
//  MerchantCategoriesVM.swift
//  YQueue
//
//  Created by Toshio on 27/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantCategoriesVM: NSObject, ModelTableViewCellModelProtocol {
    
    var title = MutableProperty("")
    
    var saveCallback: () -> Void
    var menuCategory: MenuCategory
    var tapSignal: Signal<Void, NoError>
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String?
    var rowHeight: CGFloat? = 50
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    init(menuCategory: MenuCategory, saveCallback: @escaping () -> Void) {
        self.menuCategory = menuCategory
        self.saveCallback = saveCallback
        
        let (tapSignal, tapObserver) = Signal<Void, NoError>.pipe()
        self.tapSignal = tapSignal
        self.tapObserver = tapObserver
        
        super.init()
        
        tapSignal.observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            Storyboard.openEditMenuCategory(self.menuCategory, saveCallback: { [weak self] (menuCategory: MenuCategory?) in
                guard let `self` = self else {
                    return
                }
                
                if let menuCategory: MenuCategory = menuCategory {
                    self.title.consume(menuCategory.title)
                } else {
                    self.tableView.remove(model: self)
                }
                
                self.saveCallback()
            })
        }
    }
    
    func modelBound() {
        title.consume(menuCategory.title)
    }
}
