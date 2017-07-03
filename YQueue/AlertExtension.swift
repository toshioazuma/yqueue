//
//  AlertExtension.swift
//  YQueue
//
//  Created by Aleksandr on 04/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit

extension UIAlertController {
    static func show(okAlertIn viewController: UIViewController, withTitle title: String,
                     message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        //alert.show(viewController, sender: nil)
        viewController.view.endEditing(true)
        viewController.present(alert, animated: true, completion: nil)
    }
}
