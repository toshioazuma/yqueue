//
//  CustomerReceiptDateTimeTVC.swift
//  YQueue
//
//  Created by Toshio on 06/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerReceiptDateTimeTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet var dateTimeLabel: UILabel! {
        didSet {
            let dateDf = DateFormatter()
            dateDf.dateFormat = "dd/MM/yyyy"
            
            let timeDf = DateFormatter()
            timeDf.dateFormat = "hh:mm:ss a"
            
            dateTimeLabel.text = "\(dateDf.string(from: Date())) at \(timeDf.string(from: Date()))"
        }
    }
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol?
}
