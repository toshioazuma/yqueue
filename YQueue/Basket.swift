//
//  Basket.swift
//  YQueue
//
//  Created by Toshio on 30/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class Basket: NSObject {
    static let shared = Basket()
    
    var items = [Item]()
    var signal: Signal<[Item], NoError>
    private var observer: Observer<[Item], NoError>
    
    override init() {
        (signal, observer) = Signal<[Item], NoError>.pipe()
        
        super.init()
    }
    
    func change(optionFor forItem: Item, to option: MenuItem.Option) {
        // search if need to be replaced
        for item in items {
            if item.menuItem.id == forItem.menuItem.id {
                var optionsSame = false
                if let lhs: MenuItem.Option = item.option {
                    optionsSame = lhs.name == option.name
                }
                
                if optionsSame {
                    remove(forItem)
                    for _ in 1...forItem.count {
                        add(forItem.menuItem, option: option)
                    }
                    return
                }
            }
        }
        
        // if not replaced, just change the option
        forItem.option = option
        send()
    }
    
    func add(_ menuItem: MenuItem, option: MenuItem.Option?) {
        for item in items {
            if item.menuItem.id == menuItem.id { // item and their options may be received from multiple sources and their NSObject hashes may be not equal
                var optionsSame = item.option == nil && option == nil
                if let lhs: MenuItem.Option = item.option,
                    let rhs: MenuItem.Option = option {
                    optionsSame = lhs.name == rhs.name
                }
                
                if optionsSame {
                    print("Found an item! increase count of \(item.count) by 1")
                    item.count += 1
                    send()
                    return
                }
            }
        }
        
        items.append(Item(menuItem, option: option, count: 1))
        send()
    }
    
    func remove(_ item: Item) {
        print("basket items before remove = \(items.count)")
        items = items.filter { $0 != item }
        print("basket items after remove = \(items.count)")
        send()
    }
    
    func remove(_ menuItem: MenuItem, option: MenuItem.Option?) {
        for item in items {
            if item.menuItem == menuItem && item.option?.name == option?.name {
                item.count -= 1
                if item.count < 0 {
                    item.count = 0
                }
                break
            }
        }
        
        send()
    }
    
    private func send() {
        observer.send(value: items)
    }
    
    func clear() {
        items.removeAll()
        send()
    }
    
    class Item {
        var menuItem: MenuItem
        var option: MenuItem.Option?
        var count: Int
        var price: Double {
            return option != nil ? (option?.price)! : menuItem.price
        }
        var totalPrice: Double {
            return price * Double(count)
        }
        
        init(_ menuItem: MenuItem, option: MenuItem.Option?, count: Int) {
            self.menuItem = menuItem
            self.option = option
            self.count = count
        }
        
        static func ==(lhs: Item, rhs: Item) -> Bool {
            return lhs.menuItem == rhs.menuItem && lhs.count == rhs.count &&
                (
                    (lhs.option == nil && rhs.option == nil) ||
                    (lhs.option != nil && rhs.option != nil && lhs.option! == rhs.option!)
                )
        }
        
        static func !=(lhs: Item, rhs: Item) -> Bool {
            return !(lhs == rhs)
        }
    }
}
