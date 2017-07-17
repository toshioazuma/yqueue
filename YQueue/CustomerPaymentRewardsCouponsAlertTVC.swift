//
//  CustomerPaymentRewardsCouponsAlertTVC.swift
//  YQueue
//
//  Created by Toshio on 12/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerPaymentRewardsCouponsAlertTVC: UITableViewCell, ModelTableViewCellProtocol {

    @IBOutlet weak var label: UILabel!
    
    var labelDetailsColor: UIColor {
        return UIColor(white: 20.0/255.0, alpha: 1)
    }
    
    var labelCodeColor: UIColor {
        return UIColor(red: 29.0/255.0, green: 205.0/255.0, blue: 120.0/255.0, alpha: 1)
    }
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: CustomerPaymentRewardsCouponsAlertVM = model as! CustomerPaymentRewardsCouponsAlertVM? {
                let string = "\(model.code.uppercased()) - \(model.details)"
                let codeRange = NSString(string: string).range(of: model.code.uppercased())
                
                let text = NSMutableAttributedString(string: string)
                text.addAttribute(NSFontAttributeName,
                                  value: label.font,
                                  range: NSMakeRange(0, string.characters.count))
                text.addAttribute(NSForegroundColorAttributeName,
                                  value: labelCodeColor,
                                  range: codeRange)
                text.addAttribute(NSForegroundColorAttributeName,
                                  value: labelDetailsColor,
                                  range: NSMakeRange(codeRange.length, string.characters.count - codeRange.length))
                
                label.attributedText = text
            }
        }
    }
}
