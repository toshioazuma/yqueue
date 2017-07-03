//
//  CustomerPayVM.swift
//  YQueue
//
//  Created by Aleksandr on 05/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerPayVM: NSObject, ModelTableViewCellModelProtocol {
    
    var tapSignal: Signal<Void, NoError>
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = "Pay"
    var rowHeight: CGFloat? = 81
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    init(callback: @escaping () -> Void) {
        let (tapSignal, tapObserver) = Signal<Void, NoError>.pipe()
        tapSignal.observeValues {
            callback()
        }
    
        self.tapSignal = tapSignal
        self.tapObserver = tapObserver
        
        super.init()
    }
    
    func modelBound() {
    }
}
