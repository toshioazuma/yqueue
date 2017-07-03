//
//  CustomerOrderHistoryTVC.swift
//  YQueue
//
//  Created by Aleksandr on 08/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerOrderHistoryTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var toggleButtonWrapper: UIView!
    @IBOutlet weak var toggleButtonIcon: UIImageView!
    @IBOutlet weak var toggleButtonLabel: UILabel!
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var orderTypeLabel: UILabel?
    @IBOutlet weak var orderNumberLabel: UILabel?
    @IBOutlet weak var tableView: ModelTableView?
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint?
    @IBOutlet weak var totalPriceLabel: UILabel?
    @IBOutlet weak var feedbackButton: UIButton? {
        didSet {
            if let feedbackButton: UIButton = feedbackButton {
                feedbackButton.layer.cornerRadius = 17.5
                feedbackButton.layer.borderColor = UIColor(white: 223.0/255.0, alpha: 1).cgColor
                feedbackButton.layer.borderWidth = 1
            }
        }
    }
//    @IBOutlet weak var hideButton: UIButton?
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: CustomerOrderHistoryVM = model as! CustomerOrderHistoryVM? {
                
                toggleButtonWrapper.backgroundColor = model.order.primaryColor
                toggleButtonWrapper.layer.cornerRadius = 3
                
                let dateDf = DateFormatter()
                dateDf.dateFormat = "dd/MM/yyyy"
                let timeDf = DateFormatter()
                timeDf.dateFormat = "hh:mm a"
                
                print("order date time = \(model.order.dateTime)")
                print("order merchant = \(model.order.merchant)")
                toggleButtonIcon.image = UIImage(named: model.order.type == .takeAway ? "order_take_away" : "order_dine_in")
                toggleButtonLabel.text = "Order made \(dateDf.string(from: model.order.dateTime)) at \(timeDf.string(from: model.order.dateTime)) in \(model.order.merchant.title!)"
                if model.order.type == .dineIn {
                    toggleButtonLabel.text = toggleButtonLabel.text?.appending(" on table #\(model.order.tableNumber.aws)")
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
                        //model.tableView.reloadData()
                }
                
                if let orderTypeLabel: UILabel = orderTypeLabel,
                    let orderNumberLabel: UILabel = orderNumberLabel {
                    orderTypeLabel.text = "Type: ".appending(model.order.type == .takeAway ? "Take Away" : "Dine-in")
                    orderNumberLabel.text = "Order Number: #\(model.order.merchant.number)-\(model.order.number)"
                }
                
                if let tableView: ModelTableView = tableView,
                    let tableViewHeight: NSLayoutConstraint = tableViewHeight {
                    var models = [CustomerOrderHistoryItemVM]()
                    for item in model.order.basket.items {
                        models.append(CustomerOrderHistoryItemVM(item: item))
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
                
                if let feedbackButton: UIButton = feedbackButton {
                    feedbackButton.isHidden = model.order.isFeedbackSent
                    feedbackButton.reactive.trigger(for: .touchUpInside)
                        .take(until: modelChangeSignal!)
                        .observeValues {
                            Storyboard.openOrderFeedback(with: model.order, callback: { 
                                model.tableView.reload(cell: self)
                            })
                        }
                }
            }
        }
    }
}
