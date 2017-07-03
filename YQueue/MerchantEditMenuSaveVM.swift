//
//  MerchantEditMenuSaveVM.swift
//  YQueue
//
//  Created by Aleksandr on 25/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantEditMenuSaveVM: NSObject, ModelTableViewCellModelProtocol {
    
    var tapSignal: Signal<Void, NoError>
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = "Save"
    var rowHeight: CGFloat? = 78
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    init(tap: @escaping () -> Void) {
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
