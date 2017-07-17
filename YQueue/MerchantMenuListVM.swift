//
//  MerchantMenuListVM.swift
//  YQueue
//
//  Created by Toshio on 24/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantMenuListVM: NSObject, ModelTableViewCellModelProtocol {

    var name = MutableProperty("")
    var price = MutableProperty(0.0)
    var descriptionText = MutableProperty("")
    var options = MutableProperty<[MenuItem.Option]>([])
    var option = MutableProperty<MenuItem.Option?>(nil)
    var isSpecialOffer = MutableProperty(false)
    var photos = MutableProperty<[MenuItem.Photo]>([])
    var tagImages = MutableProperty<[UIImage]>([])
    var offset = MutableProperty<CGFloat>(0)
    
    var menuItem: MenuItem
    var tapSignal: Signal<Void, NoError>
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = nil
    var rowHeight: CGFloat?
    var estimatedRowHeight: CGFloat? = 279
    var tableView: ModelTableView!
    var editCallback: () -> Void
    var offsetCallback: (CGFloat) -> Void
    
    init(menuItem: MenuItem, editCallback: @escaping () -> Void, offsetCallback: @escaping (CGFloat) -> Void) {
        self.menuItem = menuItem
        self.editCallback = editCallback
        self.offsetCallback = offsetCallback
        
        let (tapSignal, tapObserver) = Signal<Void, NoError>.pipe()
        self.tapSignal = tapSignal
        self.tapObserver = tapObserver
        
        
        super.init()
        
        tapSignal.observe { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            Storyboard.openEditMenuItem(menuItem, saveCallback: { [weak self] _ in
                guard let `self` = self else {
                    return
                }
                
                print("item edited, options = \(menuItem.options)")
                self.modelBound()
                self.editCallback()
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "EditItem"), object: nil, userInfo: ["item":menuItem])
            })
        }
        
        offset.signal.observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.offsetCallback($0)
        }
        
        option.signal.observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            if let option: MenuItem.Option = $0 {
                self.price.consume(option.price)
            }
        }
    }
    
    func modelBound() {
        name.consume("\(menuItem.number) - \(menuItem.name)")
        descriptionText.consume(menuItem.descriptionText)
        options.consume(menuItem.options)
        if options.value.count > 0 {
            if let option: MenuItem.Option = option.value {
                var foundOption = false
                for o in options.value {
                    if o.id == option.id {
                        self.option.consume(o)
                        foundOption = true
                        break
                    }
                }
                
                if !foundOption {
                    self.option.consume(options.value[0])
                }
            } else {
                option.consume(options.value[0])
            }
        } else {
            price.consume(menuItem.price)
        }
        isSpecialOffer.consume(menuItem.specialOfferText.aws.characters.count > 0)
        photos.consume(menuItem.photos)
        
        var tagImages = [UIImage]()
        if menuItem.isBestSelling {
            tagImages.append(UIImage(named: "menu_tag_best_selling_selected")!)
        }
        if menuItem.isChefsSpecial {
            tagImages.append(UIImage(named: "menu_tag_chefs_special_selected")!)
        }
        if menuItem.isGlutenFree {
            tagImages.append(UIImage(named: "menu_tag_gluten_free_selected")!)
        }
        if menuItem.isVegeterian {
            tagImages.append(UIImage(named: "menu_tag_vegeterian_selected")!)
        }
        self.tagImages.consume(tagImages)
//        if option.value != nil {
//            print("model bound, option was \(option.value!.name)")
//        }
//        name.consumeCurrent()
//        descriptionText.consumeCurrent()
//        options.consumeCurrent()
//        option.consumeCurrent()
//        price.consumeCurrent()
//        isSpecialOffer.consumeCurrent()
//        photos.consumeCurrent()
//        tagImages.consumeCurrent()
//        if option.value != nil {
//            print("model bound, option became \(option.value!.name)")
//        }
    }
}
