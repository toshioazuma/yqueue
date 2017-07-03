//
//  MerchantSettingsVC.swift
//  YQueue
//
//  Created by Aleksandr on 22/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit

class MerchantSettingsVC: AppVC {

    @IBOutlet weak var tableView: ModelTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Settings"
        
        var models = [ModelTableViewCellModelProtocol]()
        if Api.auth.merchantUser.access == .owner {
            // edit profile
            models.append(MerchantSettingsVM(title: "Edit Restaurant", icon: UIImage(named: "settings_profile"), tap: {
                Storyboard.openEditRestaurant()
            }))
        }
        
        // change password
        models.append(MerchantSettingsVM(title: "Change password", icon: UIImage(named: "settings_password"), tap: {
            Storyboard.openChangePassword()
        }))
        
        // notification settings
        models.append(MerchantSettingsSwitchVM(title: "Notifications",
                                               icon: UIImage(named: "settings_notifications"),
                                               reuseIdentifier:"ItemSwitch",
                                               switched: Api.push.token != nil,
                                               switchingEnabled: true, tap: { [weak self] in
            if $0 {
                Api.push.register()
            } else {
                Api.push.unregister()
            }
                                                
            if let `self` = self {
                for model in self.tableView.models {
                    if let switchModel: MerchantSettingsSwitchVM = model as? MerchantSettingsSwitchVM,
                        switchModel.title == "Background printing" {
                        switchModel.switchingEnabled.consume($0)
                        
                        break
                    }
                }
            }
        }))
        
        // printing
        models.append(MerchantSettingsSwitchVM(title: "Background printing",
                                               icon: UIImage(named: "settings_print"),
                                               reuseIdentifier:"ItemSwitch",
                                               switched: Api.push.printingEnabled,
                                               switchingEnabled: Api.push.token != nil, tap: {
            Api.push.printingEnabled = $0
        }))
        
        tableView.models = models
    }
}
