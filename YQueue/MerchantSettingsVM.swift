//
//  MerchantSettingsVM.swift
//  YQueue
//
//  Created by Aleksandr on 23/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantSettingsVM: NSObject, ModelTableViewCellModelProtocol {
    
    var title: String
    var icon: UIImage?
    var tapSignal: Signal<Void, NoError>
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = nil
    var rowHeight: CGFloat? = 50
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    init(title: String, icon: UIImage?, reuseIdentifier: String?, tap: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.reuseIdentifier = reuseIdentifier
        
        let (tapSignal, tapObserver) = Signal<Void, NoError>.pipe()
        tapSignal.observe { _ in
            tap()
        }
        
        self.tapSignal = tapSignal
        self.tapObserver = tapObserver
        
        super.init()
    }
    
    convenience init(title: String, icon: UIImage?, tap: @escaping () -> Void) {
        self.init(title: title, icon: icon, reuseIdentifier: nil, tap: tap)
    }
    
    func modelBound() {
        // do nothing, since titles and icons are static
    }
}
