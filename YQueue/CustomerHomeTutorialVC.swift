//
//  CustomerHomeTutorialVC.swift
//  YQueue
//
//  Created by Toshio on 20/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit

class CustomerHomeTutorialVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func takeAwayButtonClicked() {
        self.dismiss(animated: false, completion: {
            Storyboard.openSearch(newDineIn: false)
        })
    }
    
    @IBAction func dineInButtonClicked() {
        self.dismiss(animated: false, completion: {
            Storyboard.openSearch(newDineIn: true)
        })
    }
}
