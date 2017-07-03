//
//  CustomerReceiptMapVM.swift
//  YQueue
//
//  Created by Aleksandr on 07/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerReceiptMapVM: NSObject, ModelTableViewCellModelProtocol {
    
    var merchant: Merchant
    
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = "Map"
    var rowHeight: CGFloat? = 112
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    init(merchant: Merchant) {
        self.merchant = merchant
        super.init()
    }
    
    func modelBound() {
    }
}
