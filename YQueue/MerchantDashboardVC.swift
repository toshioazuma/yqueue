//
//  MerchantDashboardVC.swift
//  YQueue
//
//  Created by Toshio on 22/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result
import MBProgressHUD

class MerchantDashboardVC: AppVC {
    
    @objc enum ViewType: Int {
        case takeAway, dineIn, all
    }
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchFieldHeight: NSLayoutConstraint!
    @IBOutlet weak var takeAwayButton: UIButton!
    @IBOutlet weak var dineInButton: UIButton!
    @IBOutlet weak var allButton: UIButton!
    @IBOutlet weak var tableView: ModelTableView!
    
    var searching: Bool {
        get {
            return searchFieldHeight.constant > 0
        }
    }
    
    var loadingOrders = false
    var models = Array<MerchantDashboardVM>()
    var modelsToShow = Array<MerchantDashboardVM>()
    var viewType = MutableProperty<ViewType>(.all)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Dashboard"
        reload()
        
        addRightButton(image: UIImage(named: "search")!).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.searchFieldHeight.constant = self.searchFieldHeight.constant == 0 ? 46 : 0
            if self.searching {
                self.searchTextField.text = ""
            }
        }
        
        addRefreshControl(to: tableView).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.reload()
        }
        
        takeAwayButton.reactive.isSelected <~ viewType.signal.map { $0 == .takeAway }
        dineInButton.reactive.isSelected <~ viewType.signal.map { $0 == .dineIn }
        allButton.reactive.isSelected <~ viewType.signal.map { $0 == .all }
        viewType.signal.observeValues { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            if self.models.count == 0 && !self.loadingOrders {
                self.loadingOrders = true
                Storyboard.showProgressHUD()
                
                Api.orders.list().observe(on: QueueScheduler.main).observeValues { [weak self] in
                    UIApplication.shared.applicationIconBadgeNumber = 0
                    
                    Storyboard.hideProgressHUD()
                    guard let `self` = self else {
                        return
                    }
                    
                    guard var orders: [Order] = $0 else {
                        UIAlertController.show(okAlertIn: self,
                                               withTitle: "Warning",
                                               message: "Couldn't load dashboard. Please check your internet connection and try again later.")
                        return
                    }
                    
                    orders.sort(by: {
                        return $0.1.dateTime.compare($0.0.dateTime) == .orderedAscending
                    })
                    
                    var models = [MerchantDashboardVM]()
                    for order in orders {
                        models.append(MerchantDashboardVM(order: order))
                    }
                    self.models = models
                    
                    self.refresh()
                    self.loadingOrders = false
                }
            } else {
                self.refresh()
            }
        }
        
        let takeAwayButtonTapSignal = takeAwayButton.reactive.trigger(for: .touchUpInside).map { self.takeAwayButton }
        let dineInButtonTapSignal = dineInButton.reactive.trigger(for: .touchUpInside).map { self.dineInButton }
        let allButtonTapSignal = allButton.reactive.trigger(for: .touchUpInside).map { self.allButton }
        
        Signal.merge([takeAwayButtonTapSignal, dineInButtonTapSignal, allButtonTapSignal]).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            let newViewType: ViewType = $0 == self.takeAwayButton ? .takeAway : $0 == self.dineInButton ? .dineIn : .all
            if self.viewType.value != newViewType {
                self.viewType.consume(newViewType)
            }
        }
        
        viewType.consumeCurrent()
        
        addTapGestureRecognizer()
        searchTextField.resignFirstResponderOnReturnButton()
        searchTextField.reactive.continuousTextValues.observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            if let searchString: String = $0 {
                self.apply(searchString: searchString)
            }
        }
        
        Api.push.newOrderSignal.take(during: self.reactive.lifetime).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.models.insert(MerchantDashboardVM(order: $0), at: 0)
            self.refresh()
        }
    }
    
    func apply(searchString: String) {
        modelsToShow.removeAll()
        models = models.filter { !$0.order.isHiddenByMerchant }
        
        for model in models {
            var add = true
            
            switch viewType.value {
            case .takeAway:
                add = model.order.type == .takeAway
                break
            case .dineIn:
                add = model.order.type == .dineIn
                break
            default:
                break
            }
            
            if add {
                var matches = true
                if searching {
                    matches = searchString.characters.count == 0
                    
                    if !matches {
                        var source = "#"
                            .appending(String(model.order.merchant.number))
                            .appending("-")
                            .appending(String(model.order.number))
                        if model.order.type == .dineIn {
                            source = source.appending(" #").appending(model.order.tableNumber)
                        }
                        
                        let searchComponents = searchString.components(separatedBy: " ")
                        for searchComponent in searchComponents {
                            if source.lowercased().contains(searchComponent.lowercased()) {
                                print("\(source.lowercased()) contains \(searchComponent.lowercased())")
                                matches = true
                                break
                            }
                        }
                    }
                }
                
                if matches {
                    modelsToShow.append(model)
                }
            }
        }
        
        tableView.models = modelsToShow
    }
    
    func refresh() {
        apply(searchString: searchTextField.text!)
    }
    
    override func reload() {
        models.removeAll()
        viewType.consumeCurrent()
    }
    
//    func prepareTestPrinter() {
//        let button = UIButton()
//        button.setTitleColor(UIColor.black, for: .normal)
//        button.setTitle("printer test", for: .normal)
//        button.sizeToFit()
//        button.center = view.center
//        view.addSubview(button)
//        
//        button.reactive.trigger(for: .touchUpInside).observeValues {
////            MBProgressHUD.showAdded(to: self.view, animated: true)
//            Storyboard.showProgressHUD()
//            OperationQueue().addOperation {
//                self.printer.start()
//            }
//        }
//        
//        printer.signal.observe(on: QueueScheduler.main).observe {
////            MBProgressHUD.hide(for: self.view, animated: true)
//            Storyboard.hideProgressHUD()
//            
//            if let error: Printer.PrinterError = $0.error {
//                var message = ""
//                
//                switch error {
//                case .couldntInit:
//                    message = "Couldn't initialize printing"
//                    break
//                case .noBluetooth:
//                    message = "Please turn on bluetooth to connect to the printer"
//                    break
//                case .noDeviceFound:
//                    message = "No printers found"
//                    break
//                case .receiptNotCreated:
//                    message = "Receipt couldn't be created"
//                    break
//                case .couldntConnect:
//                    message = "Couldn't connect to the printer"
//                    break
//                case .printingUnavailable:
//                    message = "Printing is unavailable"
//                    break
//                case .couldntPrint:
//                    message = "Couldn't start printing"
//                    break
//                case .printerOffline:
//                    message = "Printer is offline"
//                    break
//                case .printerNoResponse:
//                    message = "Couldn't receive a response from the printer"
//                    break
//                case .printerCoverOpen:
//                    message = "Please close roll paper cover"
//                    break
//                case .printerPaperFeed:
//                    message = "Please release a paper feed switch"
//                    break
//                case .printerAutocutterNeedRecover:
//                    message = "Please remove jammed paper and close roll paper cover.\nRemove any jammed paper or foreign substances in the printer, and then turn the printer off and turn the printer on again.\nThen, If the printer doesn\'t recover from error, please cycle the power switch."
//                    break
//                case .printerUnrecover:
//                    message = "Please cycle the power switch of the printer.\nIf same errors occurred even power cycled, the printer may out of order."
//                    break
//                case .printerReceiptEnd:
//                    message = "Please check roll paper"
//                    break
//                case .printerBatteryOverheat:
//                    message = "Please wait until error LED of the printer turns off.\nBattery of printer is hot."
//                    break
//                case .printerHeadOverheat:
//                    message = "Please wait until error LED of the printer turns off.\nPrint head of printer is hot."
//                    break
//                case .printerMotorOverheat:
//                    message = "Please wait until error LED of the printer turns off.\nMotor Driver IC of printer is hot."
//                    break
//                case .printerWrongPaper:
//                    message = "Please set correct roll paper"
//                    break
//                case .printerBatteryRealEnd:
//                    message = "Please connect AC adapter or change the battery.\nBattery of printer is almost empty."
//                    break
//
//                }
//                
//                UIAlertController.show(okAlertIn: self,
//                                       withTitle: "Warning",
//                                       message: message)
//            } else {
//                
//            }
//        }
//    }
}
