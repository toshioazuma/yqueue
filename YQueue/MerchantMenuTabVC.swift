//
//  MerchantMenuTabVC.swift
//  YQueue
//
//  Created by Aleksandr on 24/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import MBProgressHUD
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantMenuTabVC: ButtonBarPagerTabStripViewController {
    
    var menuCategories: [MenuCategory]? {
        didSet {
            if let menuCategories: [MenuCategory] = menuCategories {
                self.menuCategories = menuCategories.sorted(by: { (lhs: MenuCategory, rhs: MenuCategory) -> Bool in
                    return rhs.position > lhs.position
                })
            }
        }
    }
    
    @IBOutlet weak var editCategoriesButton: UIButton!
    
    override func viewDidLoad() {
        
        settings.style.buttonBarItemLeftRightMargin = 11
        settings.style.buttonBarItemBackgroundColor = UIColor.white
        settings.style.buttonBarItemFont = UIFont.systemFont(ofSize: 15)
        
        settings.style.selectedBarBackgroundColor = UIColor.clear
        settings.style.selectedBarHeight = 5
        
        editCategoriesButton.isHidden = true
        Storyboard.showProgressHUD()
        
        Api.menuCategories.list(for: Api.auth.merchantUser.merchant)
            .observe(on: QueueScheduler.main)
            .observeValues { [weak self] in
                Storyboard.hideProgressHUD()
                guard let `self` = self else {
                return
                }
                
                guard let categories: [MenuCategory] = $0 else {
                    UIAlertController.show(okAlertIn: self,
                                           withTitle: "Warning",
                                           message: "Couldn't load menu. Please check your internet connection and try again later.")
                    return
                }
            
                self.loaded(categories: categories)
        }
        
        editCategoriesButton.reactive.trigger(for: .touchUpInside).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            Storyboard.openCategories(editCallback: { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                self.menuCategories = $0
                self.reloadPagerTabStripView()
            })
        }
        
        NotificationCenter.default.reactive.notifications(forName: Notification.Name(rawValue: "AddItem")).observe { [weak self] in
            guard let `self` = self else {
                return
            }
            
            if let menuItem: MenuItem = $0.value?.userInfo?["item"] as! MenuItem?,
                !(self.menuCategories?.contains(menuItem.category))! {
                self.menuCategories?.append(menuItem.category)
                self.menuCategories = self.menuCategories?.sorted { $0.0.title < $0.1.title }
                self.reloadPagerTabStripView()
            }
        }
    }
        
    private func loaded(categories: [MenuCategory]) {
        self.menuCategories = categories.sorted { $0.0.title < $0.1.title }
        
        self.editCategoriesButton.isHidden = false
        
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        self.reloadPagerTabStripView()
    }
    
    override func viewDidLayoutSubviews() {
        if menuCategories != nil {
            super.viewDidLayoutSubviews()
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        buttonBarView.reloadData()
    }
    
    var currentIndexColor: UIColor {
        return UIColor(red: 50.0/255.0, green: 209.0/255.0, blue: 125.0/255.0, alpha: 1)
    }
    
    var indexColor: UIColor {
        return UIColor(white: 92.0/255.0, alpha: 1)
    }
    
    override func configureCell(_ cell: ButtonBarViewCell, indicatorInfo: IndicatorInfo) {
        let titles = menuCategories!.map{ $0.title } 
        let index = titles.index(of: indicatorInfo.title)
        
        cell.label.textColor = currentIndex == index ? currentIndexColor : indexColor
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        var pages = Array<UIViewController>()
        
        for menuCategory in menuCategories! {
            pages.append(Storyboard.getMenuList(for: menuCategory))
        }
        
        return pages
    }
}
