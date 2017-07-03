//
//  MerchantCategoriesTVC.swift
//  YQueue
//
//  Created by Aleksandr on 27/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantCategoriesTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: MerchantCategoriesVM = model as! MerchantCategoriesVM? {
                titleLabel.reactive.text <~ model.title.signal.take(until: modelChangeSignal!)
            }
        }
    }
}
