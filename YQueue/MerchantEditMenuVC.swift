//
//  MerchantEditMenuVC.swift
//  YQueue
//
//  Created by Aleksandr on 23/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result
import MBProgressHUD

class MerchantEditMenuVC: BaseVC {

    var menuItem: MenuItem?
    var saveCallback: ((MenuItem) -> Void)!
    var models = [ModelTableViewCellModelProtocol]()
    
    @IBOutlet weak var tableView: ModelTableView!
    @IBOutlet weak var bottomOffset: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let menuItem: MenuItem = menuItem {
            title = menuItem.name
        } else {
            title = "Add new item"
        }
        
        _ = addBackButton()
        addTapGestureRecognizer()
        keyboardSignal.observe { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.bottomOffset.constant = $0.value!
        }
        
        models.append(MerchantEditMenuPhotosVM(menuItem: menuItem))
        models.append(MerchantEditMenuDataVM(menuItem: menuItem))
        models.append(ModelTableViewCellModel(reuseIdentifier: "OptionsHeader", rowHeight: 66))
        if let menuItem: MenuItem = menuItem {
            for option in menuItem.options {
                // create model with new item option because it's being updated during edit
                // but if item is not saved, the menu item is not interested in such changes
                models.append(MerchantEditMenuOptionVM(option: MenuItem.Option(id: option.id,
                                                                               name: option.name,
                                                                               price: option.price)))
            }
        }
        models.append(MerchantEditMenuAddOptionVM(tap: { [weak self] in
            guard let `self` = self else {
                return
            }
            
            for (i, model) in self.models.enumerated() {
                if let _: MerchantEditMenuAddOptionVM = model as? MerchantEditMenuAddOptionVM {
                    self.models.insert(MerchantEditMenuOptionVM(option: MenuItem.Option(id: UUID().uuidString.lowercased(),
                                                                                        name: "",
                                                                                        price: 0.0)),
                                       at: i)
                    self.tableView.models = self.models
                    break
                }
            }
        }))
        models.append(MerchantEditMenuTagsVM(menuItem: menuItem))
        models.append(MerchantEditMenuSaveVM(tap: { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.save()
        }))
        
        if menuItem != nil {
            models.append(MerchantEditMenuDeleteVM(tap: { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                self.promptDelete()
            }))
        }
        
        tableView.models = models
    }
    
    func promptDelete() {
        let alert = UIAlertController(title: "Warning",
                                      message: "Are you sure you want to delete this item?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            if let menuItem: MenuItem = self.menuItem {
                Storyboard.showProgressHUD()
                
                Api.menuItems.delete(menuItem)
                    .observe(on: QueueScheduler.main)
                    .observe { [weak self] in
                        Storyboard.hideProgressHUD()
                        guard let `self` = self else {
                            return
                        }
                        
                        if $0.value! {
                            let alert = UIAlertController(title: "",
                                                          message: "Item successfully deleted",
                                                          preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                                NotificationCenter.default
                                    .post(name: NSNotification.Name(rawValue: "DeleteItem"),
                                          object: nil,
                                          userInfo: ["item":menuItem])
                                Storyboard.pop()
                            }))
                            self.present(alert, animated: true, completion: nil)
                        } else {
                            UIAlertController.show(okAlertIn: self,
                                                   withTitle: "Warning",
                                                   message: "Couldn't delete the item. Please check your internet connection and try again later.")
                        }
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    var saveBlock = false
    func save() {
        if saveBlock {
            return
        }
        saveBlock = true
        
        var errorMessage: String?
        var oldCategoryId: String? = self.menuItem != nil ? (self.menuItem?.categoryId) : nil
        var newItemNumber: String? = nil
        let menuItem: MenuItem = self.menuItem ?? MenuItem()
        
        var options = Array<MenuItem.Option>()
        var photos = Array<MenuItem.Photo>()
        for model in models {
            if let photosModel: MerchantEditMenuPhotosVM = model as? MerchantEditMenuPhotosVM {
                photos.append(contentsOf: photosModel.photos.value)
            } else if let dataModel: MerchantEditMenuDataVM = model as? MerchantEditMenuDataVM {
                if dataModel.menuCategory.value == nil && errorMessage == nil {
                    errorMessage = "You should choose a category"
                    break
                }
                
                if menuItem.number != dataModel.number.value {
                    newItemNumber = dataModel.number.value
                }
                
                if oldCategoryId != nil && oldCategoryId! == dataModel.menuCategory.value?.id {
                    oldCategoryId = nil
                }
                
                menuItem.name = dataModel.name.value
                menuItem.number = dataModel.number.value
                menuItem.price = dataModel.price.value
                menuItem.descriptionText = dataModel.descriptionText.value
                menuItem.specialOfferText = dataModel.specialOfferText.value
                menuItem.category = dataModel.menuCategory.value
            } else if let optionModel: MerchantEditMenuOptionVM = model as? MerchantEditMenuOptionVM {
                if optionModel.name.value.characters.count > 0 && optionModel.price.value > 0.0 {
                    options.append(MenuItem.Option(id: optionModel.id.value,
                                                   name: optionModel.name.value,
                                                   price: optionModel.price.value))
                } else if (optionModel.name.value.characters.count > 0 || optionModel.price.value > 0.0)
                    && errorMessage == nil {
                    errorMessage = "One of your options doesn't have title or its price is invalid.\nEither provide valid values or leave them empty to skip adding."
                }
            } else if let tagsModel: MerchantEditMenuTagsVM = model as? MerchantEditMenuTagsVM {
                menuItem.isBestSelling = tagsModel.bestSelling.value
                menuItem.isChefsSpecial = tagsModel.chefsSpecial.value
                menuItem.isGlutenFree = tagsModel.glutenFree.value
                menuItem.isVegeterian = tagsModel.vegeterian.value
            }
        }
        
        if errorMessage == nil {
            if menuItem.name.characters.count == 0 {
                errorMessage = "Item name shouldn't be empty"
            } else if menuItem.number.characters.count == 0 {
                errorMessage = "Item number shouldn't be empty"
            } else if options.count == 0 && menuItem.price == 0.0 {
                errorMessage = "Item price may be empty only if have options"
            } else if menuItem.descriptionText.characters.count == 0 {
                errorMessage = "Item description shouldn't be empty"
            }
        }
        
        if let errorMessage: String = errorMessage {
            UIAlertController.show(okAlertIn: self, withTitle: "Warning", message: errorMessage)
            saveBlock = false
            return
        }
        
        menuItem.options.removeAll()
        menuItem.options.append(contentsOf: options)
        
        Storyboard.showProgressHUD()
        
        var photosForUpload = Array<MenuItem.Photo>()
        for photo in photos {
            if photo.name.characters.count == 0 {
                photo.name = UUID().uuidString.lowercased()
                photosForUpload.append(photo)
            }
        }
        
        var photosForDelete = Array<MenuItem.Photo>()
        if menuItem.photos.count > 0 {
            for photo in menuItem.photos {
                var photoStillExists = false
                for newPhoto in photos {
                    if newPhoto.name == photo.name {
                        photoStillExists = true
                        break
                    }
                }
                
                if !photoStillExists {
                    photosForDelete.append(photo)
                }
            }
        }
        
        let saveCallback = { [weak self] () -> Void in
            guard let `self` = self else {
                return
            }
            
            Api.menuItems.save(menuItem,
                               oldCategoryId: oldCategoryId,
                               newItemNumber: newItemNumber)
                .observe(on: QueueScheduler.main).observe { [weak self] in
                Storyboard.hideProgressHUD()
                guard let `self` = self else {
                    return
                }
                
                self.saveBlock = false
                if let error: MenuItems.MenuItemSaveError = $0.error {
                    var errorMessage = ""
                    
                    switch error {
                    case .idDuplicate:
                        errorMessage = "Item with same number already exists. Please, choose another and try again."
                        break
                    case .couldntRemoveFromCurrentCategory:
                        errorMessage = "Couldn't move your item to new category."
                        break
                    default:
                        errorMessage = "Couldn't add new item. Please, check your internet connection or try again later."
                        break
                    }
                    
                    
                    UIAlertController.show(okAlertIn: self,
                                           withTitle: "Warning",
                                           message: errorMessage)

                } else {
                    let alert = UIAlertController(title: "",
                                                  message: "Item successfully saved",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
                        if let `self` = self {
                            self.saveCallback(menuItem)
                        }
                        Storyboard.pop()
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
        
        let uploadPhotosCallback = { [weak self] () -> Void in
            guard let `self` = self else {
                return
            }
            
            if photosForUpload.count > 0 {
                print("trying to upload \(photosForUpload.count) photos")
                Api.menuItems.upload(photos: photosForUpload, for: menuItem)
                    .observe(on: QueueScheduler.main)
                    .observe { [weak self] in
                        guard let `self` = self else {
                            Storyboard.hideProgressHUD()
                            return
                        }
                        
                        if !$0.value! {
                            print("Couldn't upload photos")
                            self.saveBlock = false
//                            MBProgressHUD.hide(for: self.view, animated: true)
                            Storyboard.hideProgressHUD()
                            
                            //                    for photo in photosForUpload {
                            //                        photo.name = ""
                            //                    }
                            
                            UIAlertController.show(okAlertIn: self,
                                                   withTitle: "Warning",
                                                   message: "Couldn't upload all images. Please, check your internet connection or try again later.")
                        } else {
                            menuItem.photos = photos
                            // convert options and photos to JSON objects
                            menuItem.prepareForSave()
                            
                            print("Successfully uploaded all photos! Continue with save")
                            saveCallback()
                        }
                }
            } else {
                // convert options to JSON objects
                menuItem.prepareForSave()
                
                saveCallback()
            }
        }
        
        if photosForDelete.count > 0 {
            Api.menuItems.delete(photos: photosForDelete, for: menuItem)
                .observe(on: QueueScheduler.main)
                .observe { [weak self] in
                    guard let `self` = self else {
                        Storyboard.hideProgressHUD()
                        return
                    }
                    
                    if !$0.value! {
                        print("Couldn't delete photos")
                        self.saveBlock = false
                        Storyboard.hideProgressHUD()
                        
                        UIAlertController.show(okAlertIn: self,
                                               withTitle: "Warning",
                                               message: "Couldn't delete old images. Please, check your internet connection or try again later.")
                    } else {
                        menuItem.photos = menuItem.photos.filter { !photosForDelete.contains($0) }
                        uploadPhotosCallback()
                    }
            }
        } else {
            uploadPhotosCallback()
        }
    }
}
