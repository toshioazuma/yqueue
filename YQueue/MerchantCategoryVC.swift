//
//  MerchantCategoryVC.swift
//  YQueue
//
//  Created by Toshio on 27/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result
import MBProgressHUD

class MerchantCategoryVC: BaseVC {
    
    var menuCategory: MenuCategory?
    var saveCallback: ((MenuCategory?) -> Void)!
    
    @IBOutlet weak var titleInput: MerchantChangePasswordInput!
    @IBOutlet weak var positionInput: MerchantChangePasswordInput!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    let form = Form()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = addBackButton()
        addTapGestureRecognizer()
        
        var maxPositionValue: Int = Api.auth.merchantUser.merchant.menuCategories.count
        if menuCategory == nil {
            maxPositionValue += 1
        }
        
        form.add(titleInput.textField, validation: .empty)
        form.add(positionInput.textField, validation: .minMax(min: 1, max: maxPositionValue))
        titleInput.checkmark.reactive.isHidden <~ (form.wrapper(for: titleInput.textField)?.invalid.signal)!
        positionInput.checkmark.reactive.isHidden <~ (form.wrapper(for: positionInput.textField)?.invalid.signal)!
        
        if let menuCategory: MenuCategory = menuCategory {
            title = "Edit Category"
            
            titleInput.textField.text = menuCategory.title
            positionInput.textField.text = String(menuCategory.position)
            
            deleteButton.reactive.trigger(for: .touchUpInside).observeValues { [weak self] in
                guard let `self` = self else {
                    return
                }
                Storyboard.showProgressHUD()
                
                Api.menuItems.list(for: menuCategory).observe(on: QueueScheduler.main).observe { [weak self] in
                    Storyboard.hideProgressHUD()
                    guard let `self` = self else {
                        return
                    }
                    
                    if let menuItems: [MenuItem] = $0.value, menuItems.count > 0 {
                        self.promptDelete(menuItems: menuItems)
                    } else {
                        self.deleteCategory(with: [])
                    }
                }
            }
        } else {
            title = "Add Category"
            positionInput.textField.text = String(maxPositionValue)
            deleteButton.isHidden = true
        }
        
        form.onSubmit(with: saveButton).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            Storyboard.showProgressHUD()
            
            if let menuCategory: MenuCategory = self.menuCategory {
                Api.menuCategories.change(menuCategory, title: $0[0], position: Int($0[1])!)
                    .observe(on: QueueScheduler.main).observe { [weak self] in
                        Storyboard.hideProgressHUD()
                        guard let `self` = self else {
                            return
                        }
                        
                        if !$0.value! {
                            UIAlertController.show(okAlertIn: self,
                                                   withTitle: "Warning",
                                                   message: "Couldn't save this category. Please, check your connection and try again later.")
                            
                        } else {
                            self.finish(with: menuCategory)
                        }
                    }
            } else {
                let menuCategory: MenuCategory = MenuCategory()
                menuCategory.title = $0[0]
                menuCategory.position = Int($0[1])!
                
                Api.menuCategories.addMenuCategory(menuCategory)
                    .observe(on: QueueScheduler.main).observe { [weak self] in
                        Storyboard.hideProgressHUD()
                        guard let `self` = self else {
                            return
                        }
                        
                        if !$0.value! {
                            UIAlertController.show(okAlertIn: self,
                                                   withTitle: "Warning",
                                                   message: "Couldn't add this category. Please, check your connection and try again later.")
                            
                        } else {
                            self.finish(with: menuCategory)
                        }
                    }
            }
        }
        
        titleInput.textField.sendActions(for: .editingChanged)
        positionInput.textField.sendActions(for: .editingChanged)
    }
    
    func promptDelete(menuItems: [MenuItem]) {
        let alert = UIAlertController(title: "Warning",
                                      message: "All items in this category will be deleted if you proceed. Are you sure you want to continue?",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            self.deleteCategory(with: menuItems)
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    func deleteCategory(with menuItems: [MenuItem]) {
        Storyboard.showProgressHUD()
        
        Api.menuCategories.delete(self.menuCategory!, menuItems: menuItems)
            .observe(on: QueueScheduler.main).observe { [weak self] in
                Storyboard.hideProgressHUD()
                guard let `self` = self else {
                    return
                }
                
                if !$0.value! {
                    UIAlertController.show(okAlertIn: self,
                                           withTitle: "Warning",
                                           message: "Couldn't delete this category. Please, check your connection and try again later.")
                } else {
                    self.finish(with: nil)
                }
        }
    }
    
    func finish(with menuCategory: MenuCategory?) {
        saveCallback(menuCategory)
        Storyboard.pop()
    }
}
