//
//  LeftMenuVC.swift
//  YQueue
//
//  Created by Aleksandr on 04/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class LeftMenuVC: BaseVC {
    
    @IBOutlet weak var photoImageView: UIImageView! {
        didSet {
            photoImageView.roundCorners()
            photoImageView.layer.borderColor = UIColor(red: 0, green: 211.0/255.0, blue: 116.0/255.0, alpha: 1).cgColor
            photoImageView.layer.borderWidth = 1
        }
    }
    @IBOutlet weak var userNameLabel: UILabel! {
        didSet {
            #if CUSTOMER
                userNameLabel.text = Api.auth.name
                userNameLabel.reactive.text <~ Api.auth.reactive
                    .values(forKeyPath: "name")
                    .map { $0 as! String? }
                    .filter { $0 != nil }
                    .map { $0! }
                    .take(during: self.reactive.lifetime)
            #else
                userNameLabel.text = Api.auth.merchantUser.merchant.title
                userNameLabel.reactive.text <~ Api.auth.merchantUser.merchant.reactive
                    .values(forKeyPath: "title")
                    .map { $0 as! String }
                    .take(during: self.reactive.lifetime)
            #endif
        }
    }
    @IBOutlet weak var tableView: ModelTableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        print("LEFT MENU VC VIEW DID LOAD")
        hideNavigationBar()
        
        var models = Array<LeftMenuItemVM>()
        
        #if MERCHANT
            // dashboard
            models.append(LeftMenuItemVM(title: "Dashboard", icon: UIImage(named: "menu_dashboard"), tap: {
                Storyboard.openHome()
            }))
            
            if Api.auth.merchantUser.access == .owner {
                // menu
                models.append(LeftMenuItemVM(title: "Menu", icon: UIImage(named: "menu_menu"), tap: {
                    Storyboard.openMenu()
                }))
            }
            
            // settings
            models.append(LeftMenuItemVM(title: "Settings", icon: UIImage(named: "menu_settings"), tap: {
                Storyboard.openSettings()
            }))
            
            if Api.auth.merchantUser.access == .owner {
                // feedback
                models.append(LeftMenuItemVM(title: "Feedback", icon: UIImage(named: "menu_feedback"), tap: {
                    Storyboard.openFeedback()
                }))
            }
        
        #endif
        
        #if CUSTOMER
            // home
            models.append(LeftMenuItemVM(title: "Home", icon: UIImage(named: "menu_home"), tap: {
                Storyboard.openHome()
            }))
                
            // search
            models.append(LeftMenuItemVM(title: "Search", icon: UIImage(named: "menu_search"), tap: {
                Storyboard.openSearch()
            }))
            
            // settings
            models.append(LeftMenuItemVM(title: "Settings", icon: UIImage(named: "menu_settings"), tap: {
                Storyboard.openSettings()
            }))
            
            // active rewards
            models.append(LeftMenuItemVM(title: "Active Rewards", icon: UIImage(named: "menu_rewards"), tap: {
                Storyboard.openActiveRewards()
            }))
            
            // order history
            models.append(LeftMenuItemVM(title: "Order History", icon: UIImage(named: "menu_order_history"), tap: {
                Storyboard.openOrderHistory()
            }))
        #endif
        
        // logout
        models.append(LeftMenuItemVM(title: "Logout", icon: UIImage(named: "menu_logout"), tap: {
            Storyboard.logout()
        }))
        
        tableView.models = models
    }
    
    @IBAction func menuButtonClicked() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "SideMenuTap"), object: nil)
        navigationController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
