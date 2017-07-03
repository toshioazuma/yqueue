//
//  MerchantMenuVC.swift
//  YQueue
//
//  Created by Aleksandr on 22/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit

class MerchantMenuVC: AppVC {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Menu"
        
        addRightButton(type: .add).observeValues {
            Storyboard.openAddMenuItem(saveCallback: {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AddItem"), object: nil, userInfo: ["item":$0])
            })
        }
    }
}
