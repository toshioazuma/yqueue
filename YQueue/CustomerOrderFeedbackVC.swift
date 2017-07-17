//
//  CustomerOrderFeedbackVC.swift
//  YQueue
//
//  Created by Toshio on 27/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result
import Cosmos

class CustomerOrderFeedbackVC: BaseVC {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var ambienceRatingView: CosmosView!
    @IBOutlet weak var ambienceViewHeight: NSLayoutConstraint!
    @IBOutlet weak var qualityOfServiceView: CosmosView!
    @IBOutlet weak var qualityOfFoodView: CosmosView!
    @IBOutlet weak var commentTextView: UITextView! {
        didSet {
            commentTextView.setCharactersLimit(1000)
        }
    }
    @IBOutlet weak var sendButton: UIButton!
    
    var order: Order!
    var callback: (() -> Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        _ = addBackButton()
        
        if order.type == .takeAway {
            headerLabel.text = "Please rate your order from \(order.merchant.title!)"
            ambienceViewHeight.constant = 0
        } else {
            headerLabel.text = "Please rate your visit at \(order.merchant.title!)"
        }
        
        sendButton.reactive.trigger(for: .touchUpInside).observeValues { [weak self] in
            if let `self` = self {
                self.send()
            }
        }
    }
    
    private func send() {
        var errorMessage: String? = nil
        
        if order.type == .dineIn && ambienceRatingView.rating == 0 {
            errorMessage = "Please choose rating for ambience"
        } else if qualityOfServiceView.rating == 0 {
            errorMessage = "Please choose rating for quality of service"
        } else if qualityOfFoodView.rating == 0 {
            errorMessage = "Please choose rating for quality of food"
        }
        
        if let errorMessage: String = errorMessage {
            UIAlertController.show(okAlertIn: self, withTitle: "Warning", message: errorMessage)
            return
        }
        
        let feedback: OrderFeedback = OrderFeedback()
        feedback.ambience = order.type == .takeAway ? 0 : Int(round(ambienceRatingView.rating))
        feedback.qualityOfService = Int(round(qualityOfServiceView.rating))
        feedback.qualityOfFood = Int(round(qualityOfFoodView.rating))
        feedback.comment = commentTextView.text
        
        Storyboard.showProgressHUD()
        Api.orders.post(feedback: feedback, for: order)
            .observe(on: QueueScheduler.main)
            .observeValues { [weak self] in
                Storyboard.hideProgressHUD()
                guard let `self` = self else {
                    return
                }
                
                if $0 {
                    self.callback()
                    Storyboard.pop()
                } else {
                    UIAlertController.show(okAlertIn: self,
                                           withTitle: "Warning",
                                           message: "Couldn't send your feedback")
                }
        }
    }
}
