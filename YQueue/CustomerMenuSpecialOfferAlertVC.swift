//
//  CustomerMenuSpecialOfferAlertVC.swift
//  YQueue
//
//  Created by Aleksandr on 11/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerMenuSpecialOfferAlertVC: AlertVC {
    
//    @IBOutlet override internal weak var wrapper: UIView! {
//        didSet {
//            self.wrapper.layer.cornerRadius = 15
//        }
//    }
    
    @IBOutlet private weak var merchantLabel: UILabel! {
        didSet {
            merchantLabel.text = merchant.title
        }
    }
    @IBOutlet private weak var offerLabel: UILabel! {
        didSet {
            currentTextIndex = 0
        }
    }
    
    @IBOutlet private weak var prevButton: UIButton! {
        didSet {
            prevButton.reactive.trigger(for: .touchUpInside)
                .filter { [weak self] in
                    guard let `self` = self else {
                        return false
                    }
                    
                    return self.texts.count > 0
                }
                .observeValues { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    
                    self.currentTextIndex -= 1
                }
        }
    }
    
    @IBOutlet private weak var nextButton: UIButton! {
        didSet {
            nextButton.reactive.trigger(for: .touchUpInside)
                .filter { [weak self] in
                    guard let `self` = self else {
                        return false
                    }
                    
                    return self.texts.count > 0
                }
                .observeValues { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    
                    self.currentTextIndex += 1
                }
        }
    }
    
    @IBOutlet private weak var closeButton: UIButton! {
        didSet {
            closeButtonSignal = closeButton.reactive.trigger(for: .touchUpInside)
            closeButtonSignal.observeValues { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    var closeButtonSignal: Signal<Void, NoError>!
    var merchant: Merchant!
    
    var texts: Array<String>!
    var currentTextIndex = 0 {
        didSet {
            if texts.count > 0 {
                if currentTextIndex < 0 {
                    currentTextIndex = texts.count-1
                } else if currentTextIndex > texts.count-1 {
                    currentTextIndex = 0
                } else {
                    if (offerLabel.text?.characters.count)! > 0 {
                        UIView.transition(with: offerLabel,
                                                  duration: 0.25,
                                                  options: [.transitionCrossDissolve],
                                                  animations: { [weak self] in
                                                    guard let `self` = self else {
                                                        return
                                                    }
                                                    
                                                    self.offerLabel.text = self.texts[self.currentTextIndex]
                                                    
                        }, completion: nil)
                    } else {
                        // initial set
                        offerLabel.text = texts[currentTextIndex]
                    }
                }
            }
        }
    }
    
    static func show(in vc: UIViewController, forMerchant merchant: Merchant, texts: Array<String>) -> CustomerMenuSpecialOfferAlertVC {
        let alert = Storyboard.specialOfferAlert()
        alert.modalPresentationStyle = .overCurrentContext
        alert.texts = texts
        alert.merchant = merchant
        
        alert.show(in: vc, animated: true)
        
        return alert
    }
}
