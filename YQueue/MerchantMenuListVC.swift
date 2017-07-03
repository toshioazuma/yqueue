//
//  MerchantMenuListVC.swift
//  YQueue
//
//  Created by Aleksandr on 24/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import MBProgressHUD
import XLPagerTabStrip
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantMenuListVC: UIViewController, IndicatorInfoProvider {
    
    var models = Array<MerchantMenuListVM>()
    var menuCategory: MenuCategory!
    var menuItems: [MenuItem]?
    
    @IBOutlet weak var tableView: ModelTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Storyboard.showProgressHUD()
        
        Api.menuItems.list(for: menuCategory).observe(on: QueueScheduler.main).observe { [weak self] in
            Storyboard.hideProgressHUD()
            guard let `self` = self else {
                return
            }
            
            if let menuItems: [MenuItem] = $0.value {
                self.menuItems = menuItems
                
                for menuItem in menuItems {
                    self.addMenuItem(menuItem, immediatePresent: false)
                }
                
                self.sort()
            }
        }
        
        NotificationCenter.default.reactive
            .notifications(forName: Notification.Name(rawValue: "AddItem"))
            .observe { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                if let menuItem: MenuItem = $0.value?.userInfo?["item"] as! MenuItem?,
                    menuItem.category == self.menuCategory {
                    self.addMenuItem(menuItem, immediatePresent: true)
                }
            }
        
        NotificationCenter.default.reactive
            .notifications(forName: Notification.Name(rawValue: "EditItem"))
            .observe { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                if let menuItem: MenuItem = $0.value?.userInfo?["item"] as! MenuItem? {
                    print("menu item not in this category = \(!(self.menuItems?.contains(menuItem))!)")
                    print("menu item category is me = \(menuItem.category == self.menuCategory)")
                    if !(self.menuItems?.contains(menuItem))! && menuItem.category == self.menuCategory {
                        self.addMenuItem(menuItem, immediatePresent: true)
                    }
                }
            }
        
        NotificationCenter.default.reactive
            .notifications(forName: Notification.Name(rawValue: "DeleteItem"))
            .observe { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                if let menuItem: MenuItem = $0.value?.userInfo?["item"] as! MenuItem?,
                menuItem.category == self.menuCategory {
                    self.removeMenuItem(menuItem)
                }
            }
    }
    
    func addMenuItem(_ menuItem: MenuItem, immediatePresent: Bool) {
        if !(menuItems?.contains(menuItem))! {
            print("add to menu items")
            menuItems?.append(menuItem)
        }
        
        models.append(MerchantMenuListVM(menuItem: menuItem, editCallback: { [weak self] in
            guard let `self` = self else {
                return
            }
            
            if (self.menuItems?.contains(menuItem))! && menuItem.category != self.menuCategory {
                self.removeMenuItem(menuItem)
            }
            self.sort()
        }, offsetCallback: { [weak self] in
            guard let `self` = self else {
                return
            }
            
            var offset = self.tableView.contentOffset
            offset.y += $0
            self.tableView.contentOffset = offset
        }))
        
        if immediatePresent {
            sort()
        }
    }
    
    func removeMenuItem(_ menuItem: MenuItem) {
        if (menuItems?.contains(menuItem))! {
            menuItems = menuItems?.filter { $0 != menuItem }
            models = models.filter { $0.menuItem != menuItem }
        }
        self.sort()
    }
    
    func sort () {
        tableView.models = models.sorted { $0.0.menuItem.number < $0.1.menuItem.number }
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: menuCategory.title)
    }
}
