//
//  MerchantDashboardTVC.swift
//  YQueue
//
//  Created by Aleksandr on 15/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantDashboardTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var toggleButtonWrapper: UIView!
    @IBOutlet weak var toggleButtonIcon: UIImageView!
    @IBOutlet weak var toggleButtonLabel: UILabel!
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var orderTypeLabel: UILabel?
    @IBOutlet weak var orderNumberLabel: UILabel?
    @IBOutlet weak var tableView: ModelTableView?
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint?
    @IBOutlet weak var totalPriceLabel: UILabel?
    @IBOutlet weak var pickUpButton: UIButton? {
        didSet {
            if let pickUpButton: UIButton = pickUpButton {
                pickUpButton.layer.cornerRadius = 17.5
            }
        }
    }
    @IBOutlet weak var completeButton: UIButton? {
        didSet {
            if let completeButton: UIButton = completeButton {
                completeButton.layer.cornerRadius = 17.5
            }
        }
    }
    @IBOutlet weak var hideButton: UIButton? {
        didSet {
            if let hideButton: UIButton = hideButton {
                hideButton.layer.cornerRadius = 17.5
                hideButton.layer.borderColor = UIColor(white: 223.0/255.0, alpha: 1).cgColor
                hideButton.layer.borderWidth = 1
            }
        }
    }
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: MerchantDashboardVM = model as! MerchantDashboardVM? {
                
                toggleButtonWrapper.backgroundColor = model.order.primaryColor
                toggleButtonWrapper.layer.cornerRadius = 3
                
                let dateDf = DateFormatter()
                dateDf.dateFormat = "dd/MM/yyyy"
                let timeDf = DateFormatter()
                timeDf.dateFormat = "hh:mm a"
                
                toggleButtonIcon.image = UIImage(named: model.order.type == .takeAway ? "order_take_away" : "order_dine_in")
                if model.order.type == .takeAway {
                    toggleButtonLabel.text = "Order made \(dateDf.string(from: model.order.dateTime)) at \(timeDf.string(from: model.order.dateTime)) by client \(model.order.customerName)"
                } else {
                    toggleButtonLabel.text = "Order made \(dateDf.string(from: model.order.dateTime)) at \(timeDf.string(from: model.order.dateTime)) by client \(model.order.customerName), table #\(model.order.tableNumber.aws)"
                }
                
                toggleButton.reactive.trigger(for: .touchUpInside)
                    .take(until: modelChangeSignal!)
                    .take(first: 1) // otherwise the cell is reloaded
                    .observeValues { [weak self] in
                        guard let `self` = self else {
                            return
                        }
                        
                        model.selected.consume(!model.selected.value)
                        model.tableView.reload(cell: self)
                    }
                
                if let orderTypeLabel: UILabel = orderTypeLabel,
                    let orderNumberLabel: UILabel = orderNumberLabel {
                    orderTypeLabel.text = "Type: ".appending(model.order.type == .takeAway ? "Take Away" : "Dine-in")
                    orderNumberLabel.text = "Order Number: #\(model.order.merchant.number)-\(model.order.number)"
                }
                
                if let tableView: ModelTableView = tableView,
                    let tableViewHeight: NSLayoutConstraint = tableViewHeight {
                    var models = [MerchantDashboardItemVM]()
                    for item in model.order.basket.items {
                        models.append(MerchantDashboardItemVM(item: item))
                    }
                    tableView.models = models
                    tableView.layoutIfNeeded()
                    OperationQueue.main.addOperation { [weak self] in
                        guard let `self` = self else {
                            return
                        }
                        
                        // dispatch async to let tableview load contents and generate height
                        tableViewHeight.constant = tableView.contentSize.height
                        if model.orderTableViewHeight.value != tableViewHeight.constant {
                            model.orderTableViewHeight.consume(tableViewHeight.constant)
                            model.tableView.reload(cell: self)
                        }
                    }
                }
                
                if let totalPriceLabel: UILabel = totalPriceLabel {
                    let totalPrice = model.order.basket.items.map{ $0.totalPrice }.reduce(0, +)
                    totalPriceLabel.text = "$\(totalPrice.format(precision: 2, ignorePrecisionIfRounded: true))"
                }
                
                if let pickUpButton: UIButton = pickUpButton,
                    let completeButton: UIButton = completeButton,
                    let hideButton: UIButton = hideButton {
                    
                    pickUpButton.isHidden = model.order.isPickedUp || model.order.type == .dineIn
                    completeButton.isHidden = model.order.isCompleted
                    hideButton.isHidden = !(pickUpButton.isHidden && completeButton.isHidden)
                    
                    pickUpButton.reactive.trigger(for: .touchUpInside)
                        .take(until: modelChangeSignal!)
                        .observeValues { [weak self] in
                            guard let `self` = self else {
                                return
                            }
                            
                            Storyboard.showProgressHUD()
                            Api.orders.pickUp(model.order)
                                .observe(on: QueueScheduler.main)
                                .observe { [weak self] in
                                    Storyboard.hideProgressHUD()
                                    guard let `self` = self else {
                                        return
                                    }
                                    
                                    if !$0.value! {
                                        UIAlertController.show(okAlertIn: Storyboard.appVC!,
                                                               withTitle: "Warning",
                                                               message: "Unfortunately couldn't pick up the order. Please try again later.")
                                    } else {
                                        model.tableView.reload(cell: self)
                                    }
                                }
                    }
                    
                    completeButton.reactive.trigger(for: .touchUpInside)
                        .take(until: modelChangeSignal!)
                        .observeValues { [weak self] in
                            guard let `self` = self else {
                                return
                            }
                            
                            Storyboard.showProgressHUD()
                            Api.orders.completed(model.order)
                                .observe(on: QueueScheduler.main)
                                .observe { [weak self] in
                                    Storyboard.hideProgressHUD()
                                    guard let `self` = self else {
                                        return
                                    }
                                    
                                    if !$0.value! {
                                        UIAlertController.show(okAlertIn: Storyboard.appVC!,
                                                               withTitle: "Warning",
                                                               message: "Unfortunately couldn't complete the order. Please try again later.")
                                    } else {
                                        model.tableView.reload(cell: self)
                                    }
                            }
                    }
                    
                    hideButton.reactive.trigger(for: .touchUpInside)
                        .take(until: modelChangeSignal!)
                        .observeValues { [weak self] in
                            guard let `self` = self else {
                                return
                            }
                            
//                            let modelIndex: Int = model.tableView.models.index { ($0 as! NSObject) == model }!
//                            var nextModel: NSObject? = nil
//                            if model.tableView.models.count > modelIndex+1 {
//                                // not last object
//                                nextModel = model.tableView.models[modelIndex+1] as? NSObject
//                            }
//                            
//                            model.tableView.remove(model: model)
                            
                            Storyboard.showProgressHUD()
                            Api.orders.hide(model.order)
                                .observe(on: QueueScheduler.main)
                                .observe { [weak self] in
                                    Storyboard.hideProgressHUD()
                                    if !$0.value! {
//                                        var models = model.tableView.models
//                                        if let nextModel: NSObject = nextModel {
//                                            // check for index, it may be changed during receiving new orders
//                                            let nextModelIndex = model.tableView.models.index { ($0 as! NSObject) == nextModel }!
//                                            // now add before it
//                                            models.insert(model, at: nextModelIndex)
//                                        } else {
//                                            // remove model to the end of the list
//                                            models.append(model)
//                                        }
//                                        model.tableView.models = models
                                        
                                        UIAlertController.show(okAlertIn: Storyboard.appVC!,
                                                               withTitle: "Warning",
                                                               message: "Unfortunately couldn't hide the order. Please try again later.")
                                    } else {
                                        // ignore, model already removed
                                        model.tableView.remove(model: model)
                                    }
                            }
                    }
                    
                }
            }
        }
    }
}
