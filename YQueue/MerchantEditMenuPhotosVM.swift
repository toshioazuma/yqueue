//
//  MerchantEditMenuPhotosVM.swift
//  YQueue
//
//  Created by Toshio on 10/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantEditMenuPhotosVM: NSObject, ModelTableViewCellModelProtocol {
    
    var photos = MutableProperty<[MenuItem.Photo]>([])
    
    var menuItem: MenuItem?
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = "Photos"
    var rowHeight: CGFloat? = 70
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    init(menuItem: MenuItem?) {
        self.menuItem = menuItem
        super.init()
    }
    
    func modelBound() {
        if let menuItem: MenuItem = menuItem {
            photos.consume(menuItem.photos)
        } else {
            photos.consumeCurrent()
        }
    }
    
    func addPhoto(_ photo: UIImage) {
        var photos = self.photos.value
        photos.append(MenuItem.Photo(item: menuItem, image: photo))
        self.photos.consume(photos)
    }
}
