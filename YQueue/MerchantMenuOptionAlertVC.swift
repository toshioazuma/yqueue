//
//  MerchantMenuOptionAlertVC.swift
//  YQueue
//
//  Created by Toshio on 25/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit

class MerchantMenuOptionAlertVC: AlertVC {
    
    var options: Array<MenuItem.Option>!
    var optionLabel: UILabel!
    var selectionCallback: ((MenuItem.Option) -> Void)!
    var offsetCallback: ((CGFloat) -> Void)!
    var offset: CGFloat = 0
    
    @IBOutlet var tableView: ModelTableView! {
        didSet {
            tableView.layer.borderColor = UIColor(white: 228.0/255.0, alpha: 1).cgColor
            tableView.layer.borderWidth = 1
        }
    }
    
    @IBOutlet weak var backgroundButton: UIButton!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tableViewTopOffset: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showBackground = false
        
        backgroundButton.reactive.trigger(for: .touchUpInside).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.offsetCallback(-self.offset)
            self.dismiss(animated: false)
        }
        
        tableViewHeight.constant = min(CGFloat(options.count) * 40.0, 200.0)
        tableViewTopOffset.constant = optionLabel.convert(optionLabel.frame, to: view).origin.y
        
        var models = Array<MerchantMenuOptionAlertVM>()
        for option in options {
            let model = MerchantMenuOptionAlertVM(option: option, tap: { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                self.selectionCallback(option)
                self.optionLabel.text = option.name
                self.dismiss(animated: false)
            })
            model.selected.value = optionLabel.text == option.name
            
            models.append(model)
        }
        
        tableView.models = models
        tableView.layoutIfNeeded()
        
        let bottomPoint = tableViewTopOffset.constant + tableView.contentSize.height
        print("top offset = \(tableViewTopOffset.constant), table height = \(tableView.contentSize.height)")
        print("bottomPoint = \(bottomPoint), frame height = \(view.frame.size.height - 32)")
        if bottomPoint > view.frame.size.height - 32 {
            offset = bottomPoint + 32 - view.frame.size.height
            tableViewTopOffset.constant -= offset
            offsetCallback(offset)
        }
    }
    
    static func show(in vc: UIViewController, withOptions options: Array<MenuItem.Option>, optionLabel: UILabel, selectionCallback: @escaping (MenuItem.Option) -> Void, offsetCallback: @escaping (CGFloat) -> Void) -> MerchantMenuOptionAlertVC {
        let alert = Storyboard.menuOptionAlert()
        alert.modalPresentationStyle = .overCurrentContext
        alert.modalTransitionStyle = .crossDissolve
        alert.options = options
        alert.optionLabel = optionLabel
        alert.selectionCallback = selectionCallback
        alert.offsetCallback = offsetCallback
        
        alert.show(in: vc, animated: true)
        
        return alert
    }
}
