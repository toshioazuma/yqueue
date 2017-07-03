//
//  CustomerHomeVC.swift
//  YQueue
//
//  Created by Aleksandr on 05/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerHomeVC: AppVC {

    @IBOutlet weak var greetLabel: UILabel!
    @IBOutlet weak var orLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Home"
        
        view.layoutIfNeeded()
        orLabel.layer.cornerRadius = orLabel.frame.size.height/2.0
        
        if let name = Api.auth.name {
            greetLabel.text = "Hey \(name),\nWhat would you like today?"
        }
        
        var counter = 0.0
        if counter.divided(by: 10) > 5 {
            
        }
    }
    
    override func reload() {
        if let name = Api.auth.name {
            greetLabel.text = "Hey \(name),\nWhat would you like today?"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Storyboard.openHomeTutorial()
    }
    
    @IBAction func takeAwayButtonClicked() {
        Storyboard.openSearch(newDineIn: false)
    }
    
    @IBAction func dineInButtonClicked() {
        Storyboard.openSearch(newDineIn: true)
    }
}
