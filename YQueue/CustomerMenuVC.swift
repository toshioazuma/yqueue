//
//  CustomerMenuVC.swift
//  YQueue
//
//  Created by Toshio on 05/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit

class CustomerMenuVC: BaseVC {

    var merchant: Merchant!
    
    var basketButton: BadgedBarButtonItem?
    
    
    deinit {
        print("menuvc deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Menu"
        _ = addBackButton()
        
        let basket = UIButton(frame: CGRect(x: 8, y: 0, width: 44, height: 44))
        basket.addTarget(self, action: #selector(basketButtonClicked), for: .touchUpInside)
        if let icon = UIImage(named: "menu_basket") {
            basket.setImage(icon, for: .normal)
        }
        
        basketButton = BadgedBarButtonItem(customView: basket, value: "0")
        basketButton?.shouldHideBadgeAtZero = true
        basketButton?.badgeBackgroundColor = UIColor(red: 57.0/255.0, green: 220.0/255.0, blue: 134.0/255.0, alpha: 1)
        basketButton?.badgeTextColor = UIColor.white
        basketButton?.badgeFont = UIFont.systemFont(ofSize: 10)
        addRightButton(basketButton!)
        
        Basket.shared.signal.observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            var count = 0
            for item in $0 {
                count += item.count
            }
            self.basketButton?.badgeValue = "\(count)"
        }
    }
    
    func basketButtonClicked() {
        if Storyboard.dineIn! {
            Storyboard.pop()
        } else {
            Storyboard.openOrderSlip(for: merchant)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Tab", let tabVC: CustomerMenuTabVC = segue.destination as? CustomerMenuTabVC {
            tabVC.merchant = merchant
        }
    }
}
