
//
//  MerchantFeedbackTVC.swift
//  YQueue
//
//  Created by Toshio on 28/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result
import Cosmos

class MerchantFeedbackTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var toggleButtonWrapper: UIView!
    @IBOutlet weak var toggleButtonIcon: UIImageView!
    @IBOutlet weak var toggleButtonLabel: UILabel!
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var orderTypeLabel: UILabel?
    @IBOutlet weak var orderNumberLabel: UILabel?
    @IBOutlet weak var ambienceRatingView: CosmosView?
    @IBOutlet weak var qualityOfServiceRatingView: CosmosView?
    @IBOutlet weak var qualityOfFoodRatingView: CosmosView?
    @IBOutlet weak var commentLabel: UILabel?
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: MerchantFeedbackVM = model as! MerchantFeedbackVM? {
                
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
//                toggleButtonIcon.image = UIImage(named: model.order.type == .takeAway ? "order_take_away" : "order_dine_in")
//                toggleButtonLabel.text = "Order made \(dateDf.string(from: model.order.dateTime)) at \(timeDf.string(from: model.order.dateTime)) in \(model.order.merchant.title!)"
//                if model.order.type == .dineIn {
//                    toggleButtonLabel.text = toggleButtonLabel.text?.appending(" on table #\(model.order.tableNumber.aws)")
//                }
                
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
                
                if let ambienceRatingView: CosmosView = ambienceRatingView {
                    ambienceRatingView.rating = Double(model.orderFeedback.ambience)
                }
                
                if let qualityOfServiceRatingView: CosmosView = qualityOfServiceRatingView {
                    qualityOfServiceRatingView.rating = Double(model.orderFeedback.qualityOfService)
                }
                
                if let qualityOfFoodRatingView: CosmosView = qualityOfFoodRatingView {
                    qualityOfFoodRatingView.rating = Double(model.orderFeedback.qualityOfFood)
                }
                
                if let commentLabel: UILabel = commentLabel {
                    commentLabel.text = model.orderFeedback.comment.aws
                }
            }
        }
    }
}
