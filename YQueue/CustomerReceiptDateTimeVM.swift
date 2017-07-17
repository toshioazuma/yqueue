//
//  CustomerReceiptDateTimeVM.swift
//  YQueue
//
//  Created by Toshio on 07/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerReceiptDateTimeVM: NSObject, ModelTableViewCellModelProtocol {
    
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = "OrderListHeader"
    var rowHeight: CGFloat? = 44
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    func modelBound() {
    }
}
