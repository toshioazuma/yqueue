//
//  CustomerTutorialVC.swift
//  YQueue
//
//  Created by Toshio on 20/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit

class CustomerTutorialVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button = UIButton(frame: self.view.frame)
        self.view.addSubview(button)
        button.reactive.trigger(for: .touchUpInside)
            .take(during: reactive.lifetime)
            .observeValues { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                self.dismiss(animated: false, completion: nil)
            }
    }
}
