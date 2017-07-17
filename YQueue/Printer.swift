//
//  Printer.swift
//  YQueue
//
//  Created by Toshio on 04/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class Printer: NSObject, Epos2PtrReceiveDelegate {

    enum PrinterError: Error {
        case couldntInit
        case noBluetooth
        case noDeviceFound
        case receiptNotCreated
        case couldntConnect
        case printingUnavailable
        case couldntPrint
        case printerOffline
        case printerNoResponse
        case printerCoverOpen
        case printerPaperFeed
        case printerAutocutterNeedRecover
        case printerUnrecover
        case printerReceiptEnd
        case printerBatteryOverheat
        case printerHeadOverheat
        case printerMotorOverheat
        case printerWrongPaper
        case printerBatteryRealEnd
    }

    private var printer: Epos2Printer?
    
    var order: Order
    var signal: Signal<Void, PrinterError>
    private var observer: Observer<Void, PrinterError>
    
    init(order: Order) {
        self.order = order
        (signal, observer) = Signal<Void, PrinterError>.pipe()
        super.init()
    }
    
    private func checkPrinterInstance() -> Bool {
        if printer == nil {
            printer = Epos2Printer(printerSeries: EPOS2_TM_M30.rawValue,
                                   lang: EPOS2_MODEL_ANK.rawValue)
            
            if printer == nil {
                observer.send(error: .couldntInit)
                return false
            }
        }
        
        return true
    }
    
    private func finalizePrinterInstance() {
        if printer == nil {
            return
        }
        
        printer?.clearCommandBuffer()
        printer?.setReceiveEventDelegate(nil)
        printer = nil
    }
    
    private func connectPrinter(address: String) -> Bool {
        var result: Int32 = EPOS2_SUCCESS.rawValue
        
        if printer == nil {
            return false
        }
        
        result = printer!.connect(address, timeout:Int(EPOS2_PARAM_DEFAULT))
        if result != EPOS2_SUCCESS.rawValue {
            return false
        }
        
        result = printer!.beginTransaction()
        if result != EPOS2_SUCCESS.rawValue {
            printer!.disconnect()
            return false
            
        }
        return true
    }
    
    private func isPrintable(status: Epos2PrinterStatusInfo?) -> Bool {
        if status == nil {
            return false
        }
        
        if status!.connection == EPOS2_FALSE {
            return false
        }
        else if status!.online == EPOS2_FALSE {
            return false
        }
        else {
            // print available
        }
        return true
    }
    
    public func start() {
        if !checkPrinterInstance() {
            return
        }
        
        let btConnection = Epos2BluetoothConnection()
        if btConnection == nil {
            observer.send(error: .noBluetooth)
            return
        }
        
        let BDAddress = NSMutableString()
        let result = btConnection?.connectDevice(BDAddress)
        
        if result == EPOS2_SUCCESS.rawValue {
            printer?.setReceiveEventDelegate(self)
            
            if createReceiptData() {
                var status: Epos2PrinterStatusInfo?
                
                if !connectPrinter(address: BDAddress as String) {
                    finalizePrinterInstance()
                    observer.send(error: .couldntConnect)
                    return
                }
                
                status = printer!.getStatus()
                
                if !isPrintable(status: status) {
                    finalizePrinterInstance()
                    observer.send(error: .printingUnavailable)
                    printer?.disconnect()
                    return
                }
                
                let result = printer!.sendData(Int(EPOS2_PARAM_DEFAULT))
                if result != EPOS2_SUCCESS.rawValue {
                    finalizePrinterInstance()
                    observer.send(error: .couldntPrint)
                    printer?.disconnect()
                    return
                }

            } else {
                finalizePrinterInstance()
                observer.send(error: .receiptNotCreated)
            }
        } else {
            observer.send(error: .noDeviceFound)
        }
    }
    
    
    func onPtrReceive(_ printerObj: Epos2Printer!, code: Int32, status: Epos2PrinterStatusInfo!, printJobId: String!) {
        if status == nil {
            observer.send(value: ())
            return
        }
        
        if status!.online == EPOS2_FALSE {
            observer.send(error: .printerOffline)
        } else if status!.connection == EPOS2_FALSE {
            observer.send(error: .printerNoResponse)
        } else if status!.coverOpen == EPOS2_TRUE {
            observer.send(error: .printerCoverOpen)
        } else if status!.paper == EPOS2_PAPER_EMPTY.rawValue {
            observer.send(error: .printerReceiptEnd)
        } else if status!.paperFeed == EPOS2_TRUE || status!.panelSwitch == EPOS2_SWITCH_ON.rawValue {
            observer.send(error: .printerPaperFeed)
        } else if status!.errorStatus == EPOS2_MECHANICAL_ERR.rawValue || status!.errorStatus == EPOS2_AUTOCUTTER_ERR.rawValue {
            observer.send(error: .printerAutocutterNeedRecover)
        } else if status!.errorStatus == EPOS2_UNRECOVER_ERR.rawValue {
            observer.send(error: .printerUnrecover)
        } else if status!.errorStatus == EPOS2_AUTORECOVER_ERR.rawValue {
            if status!.autoRecoverError == EPOS2_HEAD_OVERHEAT.rawValue {
                observer.send(error: .printerHeadOverheat)
            } else if status!.autoRecoverError == EPOS2_MOTOR_OVERHEAT.rawValue {
                observer.send(error: .printerBatteryOverheat)
            } else if status!.autoRecoverError == EPOS2_BATTERY_OVERHEAT.rawValue {
                observer.send(error: .printerMotorOverheat)
            } else if status!.autoRecoverError == EPOS2_WRONG_PAPER.rawValue {
                observer.send(error: .printerWrongPaper)
            }
        } else if status!.batteryLevel == EPOS2_BATTERY_LEVEL_0.rawValue {
            observer.send(error: .printerBatteryRealEnd)
        }
        
        OperationQueue().addOperation {
            self.disconnectPrinter()
        }
    }
    
    private func disconnectPrinter() {
        var result: Int32 = EPOS2_SUCCESS.rawValue
        
        if printer == nil {
            return
        }
        
        result = printer!.endTransaction()
        if result != EPOS2_SUCCESS.rawValue {
        }
        
        result = printer!.disconnect()
        if result != EPOS2_SUCCESS.rawValue {
        }
        
        finalizePrinterInstance()
    }
    
    private func printHeader() -> Bool {
        var result = EPOS2_SUCCESS.rawValue
        let textData: NSMutableString = NSMutableString()
        
        textData.append(order.type == .takeAway ? "Take Away" : "Dine In")
        textData.append("\n\n")
        if order.type == .dineIn {
            textData.append("Table number: \(order.tableNumber)\n")
        }
        textData.append("Customer name: \(order.customerName)\n")
        textData.append("Order number: #\(Api.auth.merchantUser.merchant.number)-\(order.number)\n")
        textData.append("Date            Time")
        
        let df1 = DateFormatter()
        df1.dateFormat = "dd.MM.yyyy"
        let df2 = DateFormatter()
        df2.dateFormat = "HH:mm:ss"
        
        let now = Date()
        textData.append(df1.string(from: now))
        textData.append("    ")
        textData.append(df2.string(from: now))
        textData.append("\n")
        result = printer!.addText(textData as String)
        if result != EPOS2_SUCCESS.rawValue {
            return false;
        }
        
        return true
    }
    
    private func print(item: Basket.Item) -> Bool {
        var result = EPOS2_SUCCESS.rawValue
        result = printer!.addFeedLine(1)
        if result != EPOS2_SUCCESS.rawValue {
            return false
        }
        
        let textData: NSMutableString = NSMutableString()
        
        textData.append("\n\n")
        textData.append(item.menuItem.number)
        textData.append("\n")
        
        let countString = String(item.count)
        textData.append(countString)
        textData.append(" ")
        textData.append(item.menuItem.name)
        textData.append("\n")
        if let option: MenuItem.Option = item.option {
            for _ in 0...countString.characters.count {
                textData.append(" ")
            }
            textData.append(option.name)
            textData.append("\n")
        }
        
        textData.append("\n")
        
        result = printer!.addText(textData as String)
        if result != EPOS2_SUCCESS.rawValue {
            return false;
        }
        
        return true
    }
    
    private func createReceiptData() -> Bool {
        var result = EPOS2_SUCCESS.rawValue
        result = printer!.addTextAlign(EPOS2_ALIGN_LEFT.rawValue)
        if result != EPOS2_SUCCESS.rawValue {
            return false;
        }
        
        if !printHeader() {
            return false
        }
        
        for item in order.basket.items {
            if !print(item: item) {
                return false
            }
        }
        
        result = printer!.addCut(EPOS2_CUT_FEED.rawValue)
        if result != EPOS2_SUCCESS.rawValue {
            return false
        }
        
        for item in order.basket.items {
            if !printHeader() {
                return false
            }
            
            if !print(item: item) {
                return false
            }
            
            result = printer!.addCut(EPOS2_CUT_FEED.rawValue)
            if result != EPOS2_SUCCESS.rawValue {
                return false
            }
        }
        
        return true
    }

}
