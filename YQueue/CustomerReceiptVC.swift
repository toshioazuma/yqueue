//
//  CustomerReceiptVC.swift
//  YQueue
//
//  Created by Aleksandr on 05/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerReceiptVC: BaseVC {
    
    var merchant: Merchant!
    var order: Order!
    var paymentMethod: PaymentMethod!
    @IBOutlet weak var tableView: ModelTableView!
    
    
    deinit {
        print("receiptvc deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Receipt"
        noBackButton()
        
        let basket = Basket.shared
        
        var models = [ModelTableViewCellModelProtocol]()
        models.append(CustomerReceiptHeaderVM(merchant: merchant, order: order))
        models.append(CustomerReceiptMapVM(merchant: merchant))
        models.append(CustomerReceiptDateTimeVM())
        
        for item in basket.items {
            models.append(CustomerReceiptRowVM.item(item))
        }
        
        models.append(CustomerReceiptRowVM.total(basket: basket, merchant: merchant))
        models.append(CustomerReceiptRowVM.tax(basket: basket, merchant: merchant))
        models.append(CustomerReceiptRowVM.gst(basket: basket, merchant: merchant))
        models.append(ModelTableViewCellModel(reuseIdentifier: "ChargedHeader", rowHeight: 41))
        models.append(CustomerReceiptChargedVM(basket: basket, merchant: merchant, paymentMethod: paymentMethod))
        models.append(CustomerReceiptNextVM())
        
        tableView.models = models
    }
    
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
//    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 15
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "Item\(indexPath.row+1)", for: indexPath)
//        
//        if let headerCell: CustomerReceiptHeaderTVC = cell as? CustomerReceiptHeaderTVC {
//            headerCell.merchant = merchant
//        }
//        if let mapCell: CustomerReceiptMapTVC = cell as? CustomerReceiptMapTVC {
//            mapCell.merchant = merchant
//        }
//        if let nextCell: CustomerReceiptNextTVC = cell as? CustomerReceiptNextTVC {
//            nextCell.button.addTarget(self, action: #selector(finish), for: .touchUpInside)
//        }
//        
//        return cell
//    }
//    
//    func finish() {
//        Storyboard.openHome()
//    }
//    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        let heights = [80,112,44,21,21,21,21,21,21,31,21,21,41,56,81]
//        return CGFloat(heights[indexPath.row])
//    }
}
