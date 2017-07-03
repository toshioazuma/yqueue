//
//  PaymentGateway.swift
//  YQueue
//
//  Created by Aleksandr on 22/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class PaymentGateway: NSObject {
    
    private let merchantId = "TEST97382271"
    private let mastercardApiUrl: URL = URL(string: "https://ap-gateway.mastercard.com/api/rest/version/40/merchant/")!
    
    private func paymentErrorMessageReplacement(for errorString: String) -> String {
        let dict = ["do not honour" : "Card Declined"]
        
        if let replacedValue: String = dict[errorString.lowercased()] {
            return replacedValue
        }
        
        return errorString
    }
    
    private func callMastercardApi(withPath path: String, httpMethod: String, body: Any?) -> Signal<Dictionary<String, Any>?, NoError> {
        let (signal, observer) = Signal<Dictionary<String, Any>?, NoError>.pipe()
        
        var bodyString = ""
        if let body: Any = body {
            do {
                let bodyData = try JSONSerialization.data(withJSONObject: body,
                                                          options: JSONSerialization.WritingOptions())
                if let bodyDataString: String = String(data: bodyData, encoding: .utf8) {
                    bodyString = bodyDataString
                } else {
                    OperationQueue.main.addOperation {
                        observer.send(value: nil)
                    }
                    return signal
                }
            } catch (_) {
                OperationQueue.main.addOperation {
                    observer.send(value: nil)
                }
                return signal
            }
        }
        
        let username = "merchant.".appending(merchantId)
        let password = "167a46a485983dcfc666f4ab8680ac03"
        let loginString = String(format: "%@:%@", username, password)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        
        let url = mastercardApiUrl
            .appendingPathComponent(merchantId)
            .appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.httpBody = bodyString.data(using: .utf8)
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue()) {
            (response: URLResponse?, data: Data?, error: Error?) in
            
            if error != nil {
                print("MasterCard api returned error = \(error)")
                observer.send(value: nil)
                return
            }
            
            guard let data: Data = data else {
                observer.send(value: nil)
                return
            }
            
            do {
                if let jsonObject: Dictionary<String, Any>
                    = try JSONSerialization.jsonObject(with: data,
                                                       options: JSONSerialization.ReadingOptions())
                        as? Dictionary<String, Any> {
                    print("MasterCard api returned object = \(jsonObject)")
                    
                    observer.send(value: jsonObject)
                } else {
                    observer.send(value: nil)
                }
            } catch(_) {
                observer.send(value: nil)
            }
        }
        
        return signal
    }
    
//    private func void(transactionWithId transactionId: String) -> Signal<Void, NoError> {
//        let (signal, observer) = Signal<Void, NoError>.pipe()
//
//        return signal
//    }
    
    func pay(order: Order, with paymentMethod: PaymentMethod, securityCode: String) -> Signal<String?, NoError> {
        let (signal, observer) = Signal<String?, NoError>.pipe()
        
        let orderNumber = "\(order.merchant.number)-\(order.number)"
        let transactionId = UUID().uuidString.lowercased()
        
        let body = [
            "apiOperation" : "PAY",
            "order" : [
                "currency" : "SGD",
                "amount" : order.totalPriceWithTax,
                "reference" : orderNumber
            ],
            "transaction" : [
                "reference" : transactionId
            ],
            "sourceOfFunds" : [
                "token" : paymentMethod.token,
                "provided" : [
                    "card" : [
                        "securityCode" : securityCode,
                    ],
                ],
            ]
        ] as [String : Any]
        
        callMastercardApi(withPath: "order/\(orderNumber)/transaction/\(transactionId)/",
                          httpMethod: "PUT",
                          body: body)
            .observeValues { [weak self] in
                if let jsonObject: Dictionary<String, Any> = $0,
                    let result: String = jsonObject["result"] as! String?,
                    let transactionResponse: [String:Any] = jsonObject["response"] as! [String:Any]? { //,
//                    let transactionResponseCode: String = transactionResponse["gatewayCode"] as! String?,
//                    let cvvResponse: [String:Any] = transactionResponse["cardSecurityCode"] as! [String:Any]?,
//                    let cvvResponseCode: String = cvvResponse["gatewayCode"] as! String? {
                    if result.lowercased() == "success" { //&&
//                        transactionResponseCode.lowercased() == "approved" &&
//                        cvvResponseCode.lowercased() == "match" {
                        observer.send(value: nil)
                    } else {
                        /*if transactionResponseCode.lowercased() == "declined" {
                            observer.send(value: "Card declined")
                        } else if transactionResponseCode.lowercased() == "timed_out" {
                            observer.send(value: "Payment timed out")
                        } else if transactionResponseCode.lowercased() == "expired_card" {
                            observer.send(value: "Your card is expired")
                        } else if cvvResponseCode.lowercased() != "match" {
                            observer.send(value: "Provided CVV code is invalid")
                        } else */if let errorMessage: String = transactionResponse["acquirerMessage"] as! String? {
                            if let `self` = self {
                                observer.send(value: self.paymentErrorMessageReplacement(for: errorMessage))
                            } else {
                                observer.send(value: errorMessage)
                            }
                        } else {
                            observer.send(value: "Payment failed")
                        }
                    }
                } else {
                    observer.send(value: "Couldn't authenticate your payment")
                }
        }
        
        return signal
    }
    
    func delete(tokenFor paymentMethod: PaymentMethod) -> Signal<Bool, NoError> {
        let (signal, observer) = Signal<Bool, NoError>.pipe()
        
        callMastercardApi(withPath: "token/".appending(paymentMethod.token),
                          httpMethod: "DELETE",
                          body: nil)
            .observeValues {
                if let jsonObject: Dictionary<String, Any> = $0 {
                    if let result: String = jsonObject["result"] as! String?,
                        result.lowercased() == "success" {
                        observer.send(value: true)
                    } else {
                        observer.send(value: false)
                    }
                } else {
                    observer.send(value: false)
                }
            }
        
        return signal
    }
    
    func tokenize(paymentMethod: PaymentMethod, withSessionId sessionId: String) -> Signal<Bool, NoError> {
        let (signal, observer) = Signal<Bool, NoError>.pipe()
        
        let body = [
            "session" : [
                "id" : sessionId
            ],
            "sourceOfFunds" : [
                "type" : "CARD"
            ]
        ]
        
        callMastercardApi(withPath: "token/",
                          httpMethod: "POST",
                          body: body)
            .observeValues {
                if let jsonObject: Dictionary<String, Any> = $0 {
                    if let result: String = jsonObject["result"] as! String?,
                        let status: String = jsonObject["status"] as! String?,
                        let token: String = jsonObject["token"] as! String?,
                        let tokenUsage: Dictionary<String, String> = jsonObject["usage"] as! Dictionary<String, String>?,
                        let tokenLastUsed: String = tokenUsage["lastUsed"],
                        result.lowercased() == "success" && status.lowercased() == "valid" {
                        
                        paymentMethod.token = token
                        paymentMethod.tokenLastUsed = tokenLastUsed
                        
                        observer.send(value: true)
                    } else {
                        observer.send(value: false)
                    }
                } else {
                    observer.send(value: false)
                }
            }
        
        return signal
    }
}
