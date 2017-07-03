//
//  CustomerActiveRewardsVC.swift
//  YQueue
//
//  Created by Aleksandr on 12/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import MBProgressHUD

class CustomerActiveRewardsVC: BaseVC, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var rewards = Array<Reward>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        MBProgressHUD.showAdded(to: view, animated: true)
//        Storyboard.showProgressHUD()
        
        self.title = "Active Rewards"
        _ = addBackButton()
        
//        Reward.testData { (rewards: Array<Reward>) in
////            MBProgressHUD.hide(for: self.view, animated: true)
//            Storyboard.hideProgressHUD()
//            self.rewards = rewards.sorted(by: { (r1: Reward, r2: Reward) -> Bool in
//                return r1.validDate < r2.validDate
//            })
//            self.tableView.reloadData()
//        }
    }
    
    deinit {
        print("activerewards deinit")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rewards.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reward = rewards[indexPath.row]
        
        let df = DateFormatter()
        df.dateFormat = "dd/MM/yy"
        
        let cell: CustomerActiveRewardsTVC = tableView.dequeueReusableCell(withIdentifier: "Item", for: indexPath) as! CustomerActiveRewardsTVC
        cell.titleLabel.text = reward.title
        cell.merchantLabel.text = reward.merchant.title
        cell.dateLabel.text = "Valid till \(df.string(from: reward.validDate))"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableCell(withIdentifier: "Header")
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
}
