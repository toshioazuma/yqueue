//
//  MerchantSettingsSwitchVM.swift
//  YQueue
//
//  Created by Toshio on 23/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantSettingsSwitchVM: NSObject, ModelTableViewCellModelProtocol {
    
    var title: String
    var icon: UIImage?
    var switched = MutableProperty(false)
    var switchingEnabled = MutableProperty(false)
    
    var tapSignal: Signal<Void, NoError>
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = nil
    var rowHeight: CGFloat? = 50
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    init(title: String, icon: UIImage?, reuseIdentifier: String?, switched: Bool, switchingEnabled: Bool, tap: @escaping (Bool) -> Void) {
        self.title = title
        self.icon = icon
        self.reuseIdentifier = reuseIdentifier
        self.switched.consume(switched)
        self.switchingEnabled.consume(switchingEnabled)
        
        let (tapSignal, tapObserver) = Signal<Void, NoError>.pipe()
        self.tapSignal = tapSignal
        self.tapObserver = tapObserver
        
        super.init()
        
        tapSignal.observe { [weak self] _ in
            if let `self` = self {
                tap(self.switched.value)
            }
        }
    }
    
    func modelBound() {
        switched.consumeCurrent()
        switchingEnabled.consumeCurrent()
    }
}
