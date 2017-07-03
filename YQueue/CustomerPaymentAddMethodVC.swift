//
//  CustomerPaymentAddMethodVC.swift
//  YQueue
//
//  Created by Aleksandr on 21/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerPaymentAddMethodVC: BaseVC, UIWebViewDelegate {
    
    var addCallback: ((PaymentMethod) -> Void)!
    @IBOutlet weak var webView: UIWebView! {
        didSet {
            webView.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = addBackButton()
        
        let url = "https://pay.yqueue.tech/payment.html"
        webView.loadRequest(URLRequest(url: URL(string: url)!))
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
//        Storyboard.
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        Storyboard.hideProgressHUD()
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        Storyboard.hideProgressHUD()
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        let successPrefix = "yqueue-success:"
        if let url: URL = request.url {
            if url.absoluteString.hasPrefix(successPrefix) {
                let base64EncodedDataString = url.absoluteString.replacingOccurrences(of: successPrefix, with: "")
                parse(base64EncodedDataString: base64EncodedDataString)
                
                return false
            }
        }
        Storyboard.showProgressHUD()
        
        return true
    }
    
    func parse(base64EncodedDataString: String) {
        print("encoded string = \(base64EncodedDataString)")
        if let data: Data = Data(base64Encoded: base64EncodedDataString),
            let string: String = String.init(data: data, encoding: .utf8) {
            let dataParts = string.components(separatedBy: "&")
            
            var dataObject = Dictionary<String, String>()
            for dataPart in dataParts {
                let parts = dataPart.components(separatedBy: "=")
                if parts.count != 2 {
                    continue
                }
                
                dataObject[parts[0]] = parts[1].removingPercentEncoding!
            }
            
            parse(dataObject: dataObject)
//            do {
//                if let jsonObject: Dictionary<String, String>
//                    = try JSONSerialization.jsonObject(with: jsonData,
//                                                       options: JSONSerialization.ReadingOptions())
//                        as? Dictionary<String, String> {
//                    parse(jsonObject: jsonObject)
//                } else {
//                    print("decoded json object is not dictionary")
//                    failedParsing()
//                }
//            } catch (_) {
//                print("cannot decode json")
//                failedParsing()
//            }
        } else {
            print("cannot decode base64")
            failedParsing()
        }
    }
    
    func parse(dataObject: Dictionary<String, String>) {
        print("parsed data object = \(dataObject)")
        guard let sessionId: String = dataObject["session_id"] else {
            print("no session id")
            failedParsing()
            return
        }
        guard let cardType: String = dataObject["card_type"] else {
            print("no card type")
            failedParsing()
            return
        }
        guard let cardNumber: String = dataObject["card_number"] else {
            print("no card number")
            failedParsing()
            return
        }
        guard let expMonth: String = dataObject["exp_m"] else {
            print("no exp month")
            failedParsing()
            return
        }
        guard let expYear: String = dataObject["exp_y"] else {
            print("no exp year")
            failedParsing()
            return
        }
        guard let cvv: String = dataObject["card_cvv"] else {
            print("no cvv")
            failedParsing()
            return
        }
        
        let paymentMethod = PaymentMethod()
        paymentMethod.type = cardType
        paymentMethod.cardNumber = cardNumber
        paymentMethod.expMonth = expMonth
        paymentMethod.expYear = expYear
        paymentMethod.cvv = cvv
        
        Storyboard.showProgressHUD()
        Api.paymentGateway.tokenize(paymentMethod: paymentMethod, withSessionId: sessionId)
            .observe(on: QueueScheduler.main)
            .observeValues { [weak self] in
                Storyboard.hideProgressHUD()
                
                if let `self` = self {
                    if $0 {
                        self.addCallback(paymentMethod)
                        Storyboard.pop()
                    } else {
                        UIAlertController.show(okAlertIn: self,
                                               withTitle: "Warning",
                                               message: "Couldn't add your payment method")
                    }
                }
            }
//        tokenize(paymentMethod: paymentMethod, withSessionId: sessionId)
    }
    
//    func tokenize(paymentMethod: PaymentMethod, withSessionId sessionId: String) {
//        Storyboard.showProgressHUD()
//        
//        let putObject = [
//            "session" : [
//                "id" : sessionId
//            ],
//            "sourceOfFunds" : [
//                "type" : "CARD"
//            ]
//        ]
//        
//        var putBody = ""
//        do {
//            let putData = try JSONSerialization.data(withJSONObject: putObject,
//                                                     options: JSONSerialization.WritingOptions())
//            if let putDataString: String = String(data: putData, encoding: .utf8) {
//                putBody = putDataString
//            } else {
//                failedParsing()
//                return
//            }
//        } catch (_) {
//            failedParsing()
//            return
//        }
//        
//        let username = "merchant.TEST97382271"
//        let password = "167a46a485983dcfc666f4ab8680ac03"
//        let loginString = String(format: "%@:%@", username, password)
//        let loginData = loginString.data(using: String.Encoding.utf8)!
//        let base64LoginString = loginData.base64EncodedString()
//        
//        let url = URL(string: "https://ap-gateway.mastercard.com/api/rest/version/40/merchant/TEST97382271/token/")!
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.httpBody = putBody.data(using: .utf8)
//        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
//        
//        print("tokenize url = \(url.absoluteString)")
//        print("tokenize body = \(putBody)")
//        
//        NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue()) { [weak self] (response: URLResponse?, data: Data?, error: Error?) in
//            guard let `self` = self else {
//                OperationQueue.main.addOperation {
//                    Storyboard.hideProgressHUD()
//                }
//                return
//            }
//            
//            if error != nil {
//                print("tokenize error = \(error)")
//                self.failedParsing()
//                return
//            }
//            
//            OperationQueue.main.addOperation { [weak self] in
//                guard let `self` = self else {
//                    return
//                }
//                
//                self.parse(tokenizeJsonData: data!, paymentMethod: paymentMethod)
//            }
//        }
//    }
//    
//    func parse(tokenizeJsonData: Data, paymentMethod: PaymentMethod) {
//        Storyboard.hideProgressHUD()
//        print("Received tokenize json data string = \(String(data: tokenizeJsonData, encoding: .utf8))")
//        do {
//            if let jsonObject: Dictionary<String, Any>
//                = try JSONSerialization.jsonObject(with: tokenizeJsonData,
//                                                   options: JSONSerialization.ReadingOptions())
//                    as? Dictionary<String, Any> {
//                print("received object = \(jsonObject)")
//                if let status: String = jsonObject["status"] as! String?,
//                    let token: String = jsonObject["token"] as! String?,
//                    let tokenUsage: Dictionary<String, String> = jsonObject["usage"] as! Dictionary<String, String>?,
//                    let tokenLastUsed: String = tokenUsage["lastUsed"],
//                    status.lowercased() == "valid" {
//                    
//                    paymentMethod.token = token
//                    paymentMethod.tokenLastUsed = tokenLastUsed
//                    
//                    addCallback(paymentMethod)
//                    Storyboard.pop()
//                } else {
//                    print("doesn't have required params")
//                    failedParsing()
//                }
//            } else {
//                print("Invalid dictionary type")
//                failedParsing()
//            }
//        } catch(_) {
//            print("Couldn't decode it as JSON")
//            failedParsing()
//        }
//    }
    
    func failedParsing() {
        OperationQueue.main.addOperation { [weak self] in
            Storyboard.hideProgressHUD()
            guard let `self` = self else {
                return
            }
            
            UIAlertController.show(okAlertIn: self,
                                   withTitle: "Warning",
                                   message: "Couldn't add your payment method")
        }
    }
}
