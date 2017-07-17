//
//  CustomerOrderHistoryVC.swift
//  YQueue
//
//  Created by Toshio on 05/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result
import MBProgressHUD

class CustomerOrderHistoryVC: AppVC {
    
    @objc enum ViewType: Int {
        case takeAway, dineIn, all
    }
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchFieldHeight: NSLayoutConstraint!
    @IBOutlet weak var takeAwayButton: UIButton!
    @IBOutlet weak var dineInButton: UIButton!
    @IBOutlet weak var allButton: UIButton!
    @IBOutlet weak var tableView: ModelTableView!
    
    var searching: Bool {
        get {
            return searchFieldHeight.constant > 0
        }
    }
    
    var loadingOrders = false
    var models = Array<CustomerOrderHistoryVM>()
    var modelsToShow = Array<CustomerOrderHistoryVM>()
    var viewType = MutableProperty<ViewType>(.all)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Order history"
        
        addRightButton(image: UIImage(named: "search")!).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.searchFieldHeight.constant = self.searchFieldHeight.constant == 0 ? 46 : 0
            if self.searching {
                self.searchTextField.text = ""
            }
        }
        
        addRefreshControl(to: tableView).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.reload()
        }
        
        takeAwayButton.reactive.isSelected <~ viewType.signal.map { $0 == .takeAway }
        dineInButton.reactive.isSelected <~ viewType.signal.map { $0 == .dineIn }
        allButton.reactive.isSelected <~ viewType.signal.map { $0 == .all }
        viewType.signal.observeValues { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            if self.models.count == 0 && !self.loadingOrders {
                self.loadingOrders = true
                Storyboard.showProgressHUD()
                
                Api.orders.list().observe(on: QueueScheduler.main).observeValues { [weak self] in
                    UIApplication.shared.applicationIconBadgeNumber = 0
                    
                    Storyboard.hideProgressHUD()
                    guard let `self` = self else {
                        return
                    }
                    
                    guard var orders: [Order] = $0 else {
                        UIAlertController.show(okAlertIn: self,
                                               withTitle: "Warning",
                                               message: "Couldn't load order history. Please check your internet connection and try again later.")
                        return
                    }
                    
                    orders.sort(by: {
                        return $0.1.dateTime.compare($0.0.dateTime) == .orderedAscending
                    })
                    
                    var models = [CustomerOrderHistoryVM]()
                    for order in orders {
                        models.append(CustomerOrderHistoryVM(order: order))
                    }
                    self.models = models
                    
                    self.refresh()
                    self.loadingOrders = false
                }
            } else {
                self.refresh()
            }
        }
        
        let takeAwayButtonTapSignal = takeAwayButton.reactive.trigger(for: .touchUpInside).map { self.takeAwayButton }
        let dineInButtonTapSignal = dineInButton.reactive.trigger(for: .touchUpInside).map { self.dineInButton }
        let allButtonTapSignal = allButton.reactive.trigger(for: .touchUpInside).map { self.allButton }
        
        Signal.merge([takeAwayButtonTapSignal, dineInButtonTapSignal, allButtonTapSignal]).observe { [weak self] in
            guard let `self` = self else {
                return
            }
            
            if let tappedButton: UIButton = $0.value! {
                let newViewType: ViewType = tappedButton == self.takeAwayButton ? .takeAway : tappedButton == self.dineInButton ? .dineIn : .all
                if self.viewType.value != newViewType {
                    self.viewType.consume(newViewType)
                }
            }
        }
        
        viewType.consumeCurrent()
        
        addTapGestureRecognizer()
        searchTextField.resignFirstResponderOnReturnButton()
        searchTextField.reactive.continuousTextValues.observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            if let searchString: String = $0 {
                self.apply(searchString: searchString)
            }
        }
    }
    
    func apply(searchString: String) {
        modelsToShow.removeAll()
        
        for model in models {
            var add = true
            
            switch viewType.value {
            case .takeAway:
                add = model.order.type == .takeAway
                break
            case .dineIn:
                add = model.order.type == .dineIn
                break
            default:
                break
            }
            
            if add {
                var matches = true
                if searching {
                    matches = searchString.characters.count == 0
                    
                    if !matches {
                        var source = "#"
                            .appending(String(model.order.merchant.number))
                            .appending("-")
                            .appending(String(model.order.number))
                        if model.order.type == .dineIn {
                            source = source.appending(" ").appending(model.order.tableNumber)
                        }
                        
                        let searchComponents = searchString.components(separatedBy: " ")
                        for searchComponent in searchComponents {
                            if source.lowercased().contains(searchComponent.lowercased()) {
                                print("\(source.lowercased()) contains \(searchComponent.lowercased())")
                                matches = true
                                break
                            }
                        }
                    }
                }
                
                if matches {
                    modelsToShow.append(model)
                }
            }
        }
        
        tableView.models = modelsToShow
    }
    
    func refresh() {
        apply(searchString: searchTextField.text!)
    }
}
