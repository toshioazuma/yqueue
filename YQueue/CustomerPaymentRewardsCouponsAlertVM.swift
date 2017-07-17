//
//  CustomerPaymentRewardsCouponsAlertVM.swift
//  YQueue
//
//  Created by Toshio on 12/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerPaymentRewardsCouponsAlertVM: NSObject, ModelTableViewCellModelProtocol {
    
    var code: String
    var details: String
    var tapSignal: Signal<Void, NoError>
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = nil
    var rowHeight: CGFloat?
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    init(code: String, details: String, tap: @escaping () -> Void) {
        self.code = code
        self.details = details
        
        let (tapSignal, tapObserver) = Signal<Void, NoError>.pipe()
        tapSignal.observe { _ in
            tap()
        }
        
        self.tapSignal = tapSignal
        self.tapObserver = tapObserver
        
        super.init()
    }

    func modelBound() {
    }
}
