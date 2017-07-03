//
//  LeftMenuItemVM.swift
//  YQueue
//
//  Created by Aleksandr on 05/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class LeftMenuItemVM: NSObject, ModelTableViewCellModelProtocol {

    var title: String
    var icon: UIImage?
    var tapSignal: Signal<Void, NoError>
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = nil
    var rowHeight: CGFloat? = 48
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    init(title: String, icon: UIImage?, tap: @escaping () -> Void) {
        self.title = title
        self.icon = icon

        let (tapSignal, tapObserver) = Signal<Void, NoError>.pipe()
        tapSignal.observe { _ in
            tap()
        }
        
        self.tapSignal = tapSignal
        self.tapObserver = tapObserver
        
        super.init()
    }
    
    func modelBound() {
        // do nothing, since titles and icons are static
    }
}
