//
//  CustomerSettingsVC.swift
//  YQueue
//
//  Created by Aleksandr on 05/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit

class CustomerSettingsVC: AppVC {
    
    @IBOutlet weak var tableView: ModelTableView!
    
    
    deinit {
        print("settingsvc deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Settings"
        
        var models = [ModelTableViewCellModelProtocol]()
        // edit profile
        models.append(CustomerSettingsVM(title: "Edit profile", icon: UIImage(named: "settings_profile"), tap: {
            Storyboard.openEditProfile()
        }))
        
        // change password
        models.append(CustomerSettingsVM(title: "Change password", icon: UIImage(named: "settings_password"), tap: {
            Storyboard.openChangePassword()
        }))
        
        // notification settings
        models.append(CustomerSettingsSwitchVM(title: "Notifications", icon: UIImage(named: "settings_notifications"), reuseIdentifier:"ItemSwitch", switched: Api.push.token != nil, tap: {
            if $0 {
                Api.push.register()
            } else {
                Api.push.unregister()
            }
        }))
        
        // payment methods
        models.append(CustomerSettingsVM(title: "Payment methods", icon: UIImage(named: "settings_payment"), tap: {
            Storyboard.openPaymentMethods()
        }))
        
        // about us
        models.append(CustomerSettingsVM(title: "About us", icon: UIImage(named: "settings_about"), tap: {
            Storyboard.openAboutUs()
        }))
        
        // cancel account
        models.append(CustomerSettingsVM(title: "Cancel account", icon: UIImage(named: "settings_cancel"), tap: {
            // TODO:
        }))
        
        tableView.models = models
    }
}
