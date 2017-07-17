//
//  CustomerRewardsCouponsVM.swift
//  YQueue
//
//  Created by Toshio on 05/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerRewardsCouponsVM: NSObject, ModelTableViewCellModelProtocol {
    
    var tapSignal: Signal<Void, NoError>
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = "RewardsCoupons"
    var rowHeight: CGFloat? = 85
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    override init() {
        let (tapSignal, tapObserver) = Signal<Void, NoError>.pipe()
        tapSignal.observeValues {
            _ = CustomerPaymentRewardsCouponsAlertVC.show(in: Storyboard.appVC!)
        }
        
        self.tapSignal = tapSignal
        self.tapObserver = tapObserver
        
        super.init()
    }
    
    func modelBound() {
    }
}
