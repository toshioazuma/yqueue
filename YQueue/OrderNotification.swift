//
//  OrderNotification.swift
//  YQueue
//
//  Created by Toshio on 22/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class OrderNotification: UIView {
    
    private lazy var headerBackgroundColor: UIColor = {
        return self.order.type == .takeAway ?
            UIColor(red: 1, green: 116.0/255.0, blue: 86.0/255.0, alpha: 1) :
            UIColor(red: 1, green: 145.0/255.0, blue: 0, alpha: 1)
    }()
    
    private lazy var headerImage: UIImage = {
        return self.order.type == .takeAway ?
            UIImage(named: "take_away_white")! :
            UIImage(named: "take_away_white")!
    }()
    
    private let order: Order
    private let textFromRemoteNotification: String?
    private var button: UIButton!
    
    static func show(order: Order) -> Signal<Void, NoError> {
        return show(order: order, textFromRemoteNotification: nil)
    }
    
    static func show(order: Order, textFromRemoteNotification: String?) -> Signal<Void, NoError> {
        let orderNotification = OrderNotification(order: order,
                                                  textFromRemoteNotification: textFromRemoteNotification)
        
        UIView.animate(withDuration: 0.3) {
            orderNotification.frame.origin.y = 28
        }
        
        let buttonSignal = orderNotification.button.reactive
            .trigger(for: .touchUpInside)
            .take(during: orderNotification.reactive.lifetime)
            .take(first: 1)
        
        buttonSignal.observeValues {
            UIView.animate(withDuration: 0.3, animations: { 
                orderNotification.frame.origin.y = -orderNotification.frame.size.height
            }, completion: { _ in
                orderNotification.removeFromSuperview()
            })
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak orderNotification] in
            if let `orderNotification` = orderNotification {
                UIView.animate(withDuration: 0.3, animations: {
                    orderNotification.frame.origin.y = -orderNotification.frame.size.height
                }, completion: { _ in
                    orderNotification.removeFromSuperview()
                })
            }
        }
        
        return buttonSignal
    }
    
    private init(order: Order, textFromRemoteNotification: String?) {
        self.order = order
        self.textFromRemoteNotification = textFromRemoteNotification
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        load()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func load() {
        guard let navVC: UINavigationController = Storyboard.appVC?.navigationController else {
            return
        }
        
        let horizontalPadding: CGFloat = 16
        let verticalPadding: CGFloat = 12
        
        frame.origin.x = horizontalPadding
        frame.size.width = navVC.view.frame.width - horizontalPadding * 2
        
        // header
        
        let headerSize: CGFloat = 35
        
        let header = UIView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: headerSize))
        header.backgroundColor = headerBackgroundColor
        addSubview(header)
        
        let headerImageView = UIImageView(frame: CGRect(x: 0,
                                                        y: 0,
                                                        width: headerSize,
                                                        height: headerSize))
        headerImageView.image = headerImage
        header.addSubview(headerImageView)
        
        let headerLabel = UILabel(frame: CGRect(x: headerSize,
                                                y: 0,
                                                width: frame.size.width - headerSize - horizontalPadding,
                                                height: headerSize))
        headerLabel.textColor = UIColor.white
        headerLabel.font = UIFont.systemFont(ofSize: 14)
        headerLabel.text = "YQueue - ".appending(order.merchant.title!)
        header.addSubview(headerLabel)
        
        // content
        
        let paragraphWidth: CGFloat = 3
        
        let content = UIView(frame: CGRect(x: 0, y: headerSize, width: frame.size.width, height: 0))
        content.backgroundColor = UIColor.white
        addSubview(content)
        
        let orderLabelX = horizontalPadding + paragraphWidth + horizontalPadding
        let orderLabel = UILabel(frame: CGRect(x: orderLabelX,
                                               y: verticalPadding,
                                               width: frame.size.width - orderLabelX - horizontalPadding,
                                               height: 0))
        orderLabel.numberOfLines = 0
        orderLabel.textColor = UIColor(white: 32.0/255.0, alpha: 1)
        orderLabel.font = UIFont.systemFont(ofSize: 12)
        orderLabel.lineBreakMode = .byWordWrapping
        
        var notificationText = ""
        
        #if MERCHANT
            var orderStringObjects = [String]()
            for item in order.basket.items {
                var stringObject = " - \(item.count) \(item.menuItem.name)"
                if let option: MenuItem.Option = item.option {
                    stringObject = stringObject.appending(" - ").appending(option.name)
                }
                orderStringObjects.append(stringObject)
            }
            
            let total = order.basket.items.map{ $0.totalPrice }.reduce(0, +)
            
            let messageObjects = ["Type: ".appending(order.type == .takeAway ? "Take Away Order" : "Dine In Order\nTable no.: ".appending(order.tableNumber)),
                                  "Client: ".appending(order.customerName),
                                  "Total: $".appending(total.format(precision: 2, ignorePrecisionIfRounded: true)),
                                  "Order:\n".appending(orderStringObjects.joined(separator: "\n"))]
            
            notificationText = messageObjects.joined(separator: "\n")
        #endif
        
        #if CUSTOMER
            if let textFromRemoteNotification: String = textFromRemoteNotification {
                notificationText = textFromRemoteNotification
            }
        #endif
        
        orderLabel.text = notificationText
        
        orderLabel.frame.size.height = orderLabel.sizeThatFits(CGSize(width: orderLabel.frame.size.width,
                                                                      height: CGFloat.greatestFiniteMagnitude)).height
        content.addSubview(orderLabel)
        
        let paragraph = UIView(frame: CGRect(x: horizontalPadding,
                                             y: verticalPadding,
                                             width: paragraphWidth,
                                             height: orderLabel.frame.size.height))
        paragraph.backgroundColor = header.backgroundColor
        paragraph.layer.cornerRadius = 1
        content.addSubview(paragraph)
        
        content.frame.size.height = verticalPadding + orderLabel.frame.size.height + verticalPadding
        frame.size.height = header.frame.size.height + content.frame.size.height
        frame.origin.y = -frame.size.height
        
        let wrapper = UIView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        wrapper.clipsToBounds = true
        wrapper.layer.cornerRadius = 12
        
        for view in subviews {
            view.removeFromSuperview()
            wrapper.addSubview(view)
        }
        addSubview(wrapper)
        
        button = UIButton(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        addSubview(button)
        
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 20)
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 8
        layer.shadowPath = UIBezierPath.init(rect: bounds).cgPath
        
        navVC.view.addSubview(self)
    }
}
