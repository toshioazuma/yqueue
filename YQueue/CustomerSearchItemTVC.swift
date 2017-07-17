//
//  CustomerSearchItemTVC.swift
//  YQueue
//
//  Created by Toshio on 05/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerSearchItemTVC: UITableViewCell, ModelTableViewCellProtocol {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var hoursLabel: UILabel!
    @IBOutlet weak var openedLabel: UILabel!
    @IBOutlet weak var closedLabel: UILabel!
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: CustomerSearchVM = model as! CustomerSearchVM? {
                nameLabel.text = model.title
                distanceLabel.reactive.text <~ model.distance.signal.take(until: modelChangeSignal!)
                hoursLabel.text = model.workingHours
                openedLabel.isHidden = !model.worksNow
                closedLabel.isHidden = model.worksNow
                
                openedLabel.layer.cornerRadius = 3
                closedLabel.layer.cornerRadius = 3
            }
        }
    }
}
