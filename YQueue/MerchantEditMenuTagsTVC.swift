//
//  MerchantEditMenuTagsTVC.swift
//  YQueue
//
//  Created by Aleksandr on 25/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantEditMenuTagsTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var bestSellingButton: UIButton!
    @IBOutlet weak var chefsSpecialButton: UIButton!
    @IBOutlet weak var glutenFreeButton: UIButton!
    @IBOutlet weak var vegeterianButton: UIButton!
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: MerchantEditMenuTagsVM = model as! MerchantEditMenuTagsVM? {
                bestSellingButton.isSelected = model.bestSelling.value
                chefsSpecialButton.isSelected = model.chefsSpecial.value
                glutenFreeButton.isSelected = model.glutenFree.value
                vegeterianButton.isSelected = model.vegeterian.value
                /*bestSellingButton.reactive.isSelected <~ model.bestSelling.signal
                    .take(until: modelChangeSignal!)
                    .take(first: 1)
                chefsSpecialButton.reactive.isSelected <~ model.chefsSpecial.signal
                    .take(until: modelChangeSignal!)
                    .take(first: 1)
                glutenFreeButton.reactive.isSelected <~ model.glutenFree.signal
                    .take(until: modelChangeSignal!)
                    .take(first: 1)
                vegeterianButton.reactive.isSelected <~ model.vegeterian.signal
                    .take(until: modelChangeSignal!)
                    .take(first: 1)*/
                
                model.bestSelling <~ bestSellingButton.reactive.values(forKeyPath: "selected")
                    .map { $0 as! Bool }.take(until: modelChangeSignal!)
                model.chefsSpecial <~ chefsSpecialButton.reactive.values(forKeyPath: "selected")
                    .map { $0 as! Bool }.take(until: modelChangeSignal!)
                model.glutenFree <~ glutenFreeButton.reactive.values(forKeyPath: "selected")
                    .map { $0 as! Bool }.take(until: modelChangeSignal!)
                model.vegeterian <~ vegeterianButton.reactive.values(forKeyPath: "selected")
                    .map { $0 as! Bool }.take(until: modelChangeSignal!)
            }
        }
    }
}
