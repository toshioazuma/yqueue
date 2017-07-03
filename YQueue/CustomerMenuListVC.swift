//
//  CustomerMenuListVC.swift
//  YQueue
//
//  Created by Aleksandr on 05/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result
import XLPagerTabStrip
import MBProgressHUD

class CustomerMenuListVC: UIViewController, IndicatorInfoProvider {
    
    var merchant: Merchant!
    var menuCategory: MenuCategory!
    var models = [CustomerMenuListVM]()
    
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
                for menuItem in menuItems {
                    self.models.append(CustomerMenuListVM(menuItem: menuItem, offsetCallback: { [weak self] in
                        guard let `self` = self else {
                            return
                        }
                        
                        var offset = self.tableView.contentOffset
                        offset.y += $0
                        self.tableView.contentOffset = offset
                    }))
                }
                
                self.sort()
            }
        }
    }
    
    func sort () {
        tableView.models = models.sorted { $0.0.menuItem.number < $0.1.menuItem.number }
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: menuCategory.title)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func addBasket() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Basket"), object: nil)
    }
}
