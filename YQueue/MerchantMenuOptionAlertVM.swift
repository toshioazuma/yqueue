//
//  MerchantMenuOptionAlertVM.swift
//  YQueue
//
//  Created by Aleksandr on 25/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantMenuOptionAlertVM: NSObject, ModelTableViewCellModelProtocol {
    
    var option: MenuItem.Option
    var selected = MutableProperty(false)
    var tapSignal: Signal<Void, NoError>
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = nil
    var rowHeight: CGFloat?
    var estimatedRowHeight: CGFloat? = 40
    var tableView: ModelTableView!
    
    init(option: MenuItem.Option, tap: @escaping () -> Void) {
        self.option = option
        
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
