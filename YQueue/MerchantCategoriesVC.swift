//
//  MerchantCategoriesVC.swift
//  YQueue
//
//  Created by Aleksandr on 27/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit

class MerchantCategoriesVC: BaseVC {
    
    var editCallback: (([MenuCategory]) -> Void)!
    
    @IBOutlet weak var tableView: ModelTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Categories"
        addBackButton().observeValues { [weak self] in
            guard let `self` = self else {
                return
            }

            self.editCallback(Api.auth.merchantUser.merchant.menuCategories)
//            self.editCallback(self.tableView.models.map { ($0 as! MerchantCategoriesVM).menuCategory })
        }
        
        reload()
        addRightButton(type: .add).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            Storyboard.openAddCategory(saveCallback: { [weak self] _ in
                guard let `self` = self else {
                    return
                }
                
                self.reload()
            })
        }
    }
    
    func reload() {
        var menuCategories = Api.auth.merchantUser.merchant.menuCategories
        menuCategories.sort { (lhs: MenuCategory, rhs: MenuCategory) -> Bool in
            return rhs.position > lhs.position
        }
        
        var models = [MerchantCategoriesVM]()
        for menuCategory in menuCategories {
            print("Merchant Categories VC, menuCategory position = \(menuCategory.position)")
            models.append(MerchantCategoriesVM(menuCategory: menuCategory, saveCallback: { [weak self] in
                guard let `self` = self else {
                return
                }
                
                self.reload()
            }))
        }
        
        tableView.models = models
    }
}
