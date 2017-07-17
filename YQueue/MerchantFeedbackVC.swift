//
//  MerchantFeedbackVC.swift
//  YQueue
//
//  Created by Toshio on 22/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result
import MBProgressHUD

class MerchantFeedbackVC: AppVC {
    
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

    var loadingFeedback = false
    var models = Array<MerchantFeedbackVM>()
    var modelsToShow = Array<MerchantFeedbackVM>()
    var viewType = MutableProperty<ViewType>(.all)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Feedback"
        
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
            
            if self.models.count == 0 && !self.loadingFeedback {
                self.loadingFeedback = true
                Storyboard.showProgressHUD()
                
                Api.orders.listFeedback()
                    .observe(on: QueueScheduler.main)
                    .observeValues { [weak self] in
                        Storyboard.hideProgressHUD()
                        guard let `self` = self else {
                            return
                        }
                        
                        guard var ordersFeedback: [OrderFeedback] = $0 else {
                            UIAlertController.show(okAlertIn: self,
                                                   withTitle: "Warning",
                                                   message: "Couldn't load feedback. Please check your internet connection and try again later.")
                            return
                        }
                        
                        ordersFeedback.sort(by: {
                            return $0.1.dateTime.compare($0.0.dateTime) == .orderedAscending
                        })
                        
                        var models = [MerchantFeedbackVM]()
                        for orderFeedback in ordersFeedback {
                            models.append(MerchantFeedbackVM(orderFeedback: orderFeedback))
                        }
                        self.models = models
                        
                        self.refresh()
                        self.loadingFeedback = false
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
                add = model.orderFeedback.order.type == .takeAway
                break
            case .dineIn:
                add = model.orderFeedback.order.type == .dineIn
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
                            .appending(String(model.orderFeedback.merchant.number))
                            .appending("-")
                            .appending(String(model.orderFeedback.order.number))
                        if model.orderFeedback.order.type == .dineIn {
                            source = source.appending(" ").appending(model.orderFeedback.order.tableNumber)
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
