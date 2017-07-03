//
//  CustomerReceiptNextVM.swift
//  YQueue
//
//  Created by Aleksandr on 07/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerReceiptNextVM: NSObject, ModelTableViewCellModelProtocol {
    
    var tapSignal: Signal<Void, NoError>
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = "Next"
    var rowHeight: CGFloat? = 81
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    override init() {
        let (tapSignal, tapObserver) = Signal<Void, NoError>.pipe()
        tapSignal.observeValues {
            Storyboard.openHome()
        }
        
        self.tapSignal = tapSignal
        self.tapObserver = tapObserver
        
        super.init()
    }
    
    func modelBound() {
    }
}
