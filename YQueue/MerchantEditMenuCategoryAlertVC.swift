//
//  MerchantEditMenuCategoryAlertVC.swift
//  YQueue
//
//  Created by Aleksandr on 25/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantEditMenuCategoryAlertVC: AlertVC {
    
    var observer: Observer<MenuCategory, NoError>!
    var menuCategories = Api.auth.merchantUser.merchant.menuCategories
    var categoryLabel: UILabel!
    
    @IBOutlet var tableView: ModelTableView! {
        didSet {
            tableView.layer.borderColor = UIColor(white: 228.0/255.0, alpha: 1).cgColor
            tableView.layer.borderWidth = 1
        }
    }
    
    @IBOutlet weak var backgroundButton: UIButton!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tableViewTopOffset: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showBackground = false
        
        backgroundButton.reactive.trigger(for: .touchUpInside).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.dismiss(animated: false)
        }
        
        tableViewHeight.constant = min(CGFloat(menuCategories.count + 1) * 40.0, 200.0)
        tableViewTopOffset.constant = categoryLabel.convert(categoryLabel.frame, to: view).origin.y + categoryLabel.frame.size.height/4.0
        
        var models = Array<MerchantEditMenuCategoryAlertVM>()
        models.append(MerchantEditMenuCategoryAlertVM(menuCategory: nil, tap: { [weak self] in
            guard let `self` = self else {
                return
            }
            
            Storyboard.openAddCategory(saveCallback: { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                if let menuCategory: MenuCategory = $0 {
                    self.observer.send(value: menuCategory)
                    self.categoryLabel.text = menuCategory.title
                }
            })
            self.dismiss(animated: false)
        }))
        
        for menuCategory in menuCategories.sorted(by: { $0.0.position < $0.1.position }) {
            let model = MerchantEditMenuCategoryAlertVM(menuCategory: menuCategory, tap: { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                self.observer.send(value: menuCategory)
                self.categoryLabel.text = menuCategory.title
                self.dismiss(animated: false)
            })
            model.selected.value = categoryLabel.text == menuCategory.title
            
            models.append(model)
        }
        
        tableView.models = models
    }
    
    static func show(in vc: UIViewController, categoryLabel: UILabel, observer: Observer<MenuCategory, NoError>) -> MerchantEditMenuCategoryAlertVC {
        let alert = Storyboard.menuCategoryAlert()
        alert.modalPresentationStyle = .overCurrentContext
        alert.modalTransitionStyle = .crossDissolve
        alert.categoryLabel = categoryLabel
        alert.observer = observer
        
        alert.show(in: vc, animated: true)
        
        return alert
    }
}
