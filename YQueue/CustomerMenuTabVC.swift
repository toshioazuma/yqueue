//
//  CustomerMenuTabVC.swift
//  YQueue
//
//  Created by Toshio on 05/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import MBProgressHUD
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerMenuTabVC: ButtonBarPagerTabStripViewController {
    
    var merchant: Merchant!
    var menuCategories: [MenuCategory]? {
        didSet {
            if let menuCategories: [MenuCategory] = menuCategories {
                self.menuCategories = menuCategories.sorted(by: { (lhs: MenuCategory, rhs: MenuCategory) -> Bool in
                    return rhs.position > lhs.position
                })
            }
        }
    }
    var specialOffers: [String]!
    
    @IBOutlet weak var specialOffersButton: UIButton!
    @IBOutlet weak var specialOffersButtonHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        
        settings.style.buttonBarItemLeftRightMargin = 11
        settings.style.buttonBarItemBackgroundColor = UIColor.white
        settings.style.buttonBarItemFont = UIFont.systemFont(ofSize: 15)
        
        settings.style.selectedBarBackgroundColor = UIColor.clear
        settings.style.selectedBarHeight = 5
        
//        MBProgressHUD.showAdded(to: view, animated: true)
        Storyboard.showProgressHUD()
        
        specialOffersButtonHeight.constant = 0
        
        Api.menuCategories.list(for: merchant)
            .observe(on: QueueScheduler.main).observeValues { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                if let categories: [MenuCategory] = $0 {
                    self.loaded(categories: categories)
                } else {
                    UIAlertController.show(okAlertIn: self,
                                           withTitle: "Warning",
                                           message: "Couldn't load menu. Please check your internet connection and try again later.")
                    Storyboard.pop()
                }
            }
        
        specialOffersButton.reactive.trigger(for: .touchUpInside).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            _ = CustomerMenuSpecialOfferAlertVC.show(in: self,
                                                     forMerchant: self.merchant,
                                                     texts: self.specialOffers)
        }
    }
    
    private func loaded(categories: [MenuCategory]) {
        menuCategories = categories
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        self.reloadPagerTabStripView()
        
        Api.menuItems.specialOffers(for: self.merchant)
            .observe(on: QueueScheduler.main).observe { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                Storyboard.hideProgressHUD()
                
                print("special offers = \($0.value!)")
                self.specialOffers = $0.value!
                if self.specialOffers.count > 0 {
                    self.specialOffersButtonHeight.constant = 39
                }
        }
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
            pages.append(Storyboard.getMenuList(for: merchant, menuCategory: menuCategory))
        }
        
        return pages
    }
}
