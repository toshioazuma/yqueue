//
//  Authorization.swift
//  YQueue
//
//  Created by Toshio on 03/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result
import AWSCore
import AWSCognito
import AWSCognitoIdentityProvider
import AWSDynamoDB
import FBSDKCoreKit
import FBSDKLoginKit

class Authorization: NSObject,
    AWSCognitoIdentityInteractiveAuthenticationDelegate,
    AWSCognitoIdentityNewPasswordRequired {
    
    enum AuthError: Error {
        case failed, requiresConfirm
    }
    
    private var pool: AWSCognitoIdentityUserPool {
        get {
            return AWS.pool
        }
    }
    
    var user: AWSCognitoIdentityUser {
        get {
            return pool.currentUser()!
        }
    }
    
    var pushToken: String? {
        get {
            return UserDefaults.standard.string(forKey: "push_token")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "push_token")
            UserDefaults.standard.synchronize()
        }
    }
    
    var username: String? {
        get {
            return UserDefaults.standard.string(forKey: "username")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "username")
            UserDefaults.standard.synchronize()
        }
    }
    
    var password: String? {
        get {
            return UserDefaults.standard.string(forKey: "password")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "password")
            UserDefaults.standard.synchronize()
        }
    }
    
    var email: String? {
        get {
            return UserDefaults.standard.string(forKey: "email")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "email")
            UserDefaults.standard.synchronize()
        }
    }
    
    #if CUSTOMER
    var name: String? {
        get {
            return UserDefaults.standard.string(forKey: "name")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "name")
            UserDefaults.standard.synchronize()
        }
    }
    
    var phone: String? {
        get {
            return UserDefaults.standard.string(forKey: "phone")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "phone")
            UserDefaults.standard.synchronize()
        }
    }
    #endif
    
    #if MERCHANT
    var merchantUser: MerchantUser!
    #endif
    
    override init() {
        super.init()
        pool.delegate = self
    }
    
    
    func logout() -> Bool {
        if let user = pool.currentUser() {
            #if MERCHANT
                if let token: String = Api.push.token,
                    merchantUser.merchant.iOSPushTokens.contains(token) {
                    remove(pushToken: token)
                }
            #endif
            
            username = nil
            password = nil
            email = nil
            #if CUSTOMER
                name = nil
                phone = nil
            #endif
            user.signOut()
            
            return true
        }
        
        return false
    }
  
    func startNewPasswordRequired() -> AWSCognitoIdentityNewPasswordRequired {
        return self
    }
    
    func getNewPasswordDetails(_ newPasswordRequiredInput: AWSCognitoIdentityNewPasswordRequiredInput,
                               newPasswordRequiredCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityNewPasswordRequiredDetails>) {
        #if MERCHANT
            newPasswordRequiredCompletionSource
                .setResult(AWSCognitoIdentityNewPasswordRequiredDetails(proposedPassword: password!,
                                                                        userAttributes: [:]))
        #endif
    }
    
    func didCompleteNewPasswordStepWithError(_ error: Error?) {
    }
    
    #if CUSTOMER
    
    func editProfile(email: String, name: String, phone: String) -> Signal<Bool, NoError> {
        let (signal, observer) = Signal<Bool, NoError>.pipe()
        
        var attributes = [AWSCognitoIdentityUserAttributeType(name: "name", value: name),
                          AWSCognitoIdentityUserAttributeType(name: "custom:phone", value: phone)]
        
        if (username?.hasPrefix("fb_"))! {
            // allow email change
            attributes.append(AWSCognitoIdentityUserAttributeType(name: "custom:fb_email", value: email))
        }
        
        user.update(attributes).continue( { [weak self] (task: AWSTask<AWSCognitoIdentityUserUpdateAttributesResponse>) -> Any? in
            if let _: Error = task.error {
                observer.send(value: false)
            } else {
                if let `self` = self {
                    self.name = name
                    self.phone = phone
                    if (self.username?.hasPrefix("fb_"))! {
                        self.email = email
                    }
                }
                
                observer.send(value: true)
            }
            
            return nil
        })
        
        return signal
    }
    
    #endif
    
    func signIn(username: String, password: String) -> Signal<Void, AuthError> {
        let (signal, observer) = Signal<Void, AuthError>.pipe()
        let task = user.getSession(username.lowercased(), password: password, validationData: nil)
        
        #if MERCHANT
            // if password change required
            self.password = password
            signal.observe {
                if let _ = $0.error {
                    self.password = nil
                }
            }
        #endif
        
        task.continue( { [unowned self] (task: AWSTask<AWSCognitoIdentityUserSession>) -> Any? in
            if task.error != nil {
                print("sign in error = \(task.error)")
                if let error: NSError = task.error as NSError? {
                    if let type: String = error.userInfo["__type"] as! String?,
                        type == "UserNotConfirmedException" {
                            observer.send(error: .requiresConfirm)
                        } else {
                            observer.send(error: .failed)
                        }
                } else {
                    observer.send(error: .failed)
                }
            } else {
                self.user.getDetails()
                    .continue({ [unowned self] (task: AWSTask<AWSCognitoIdentityUserGetDetailsResponse>) -> Any? in
                    if task.error != nil {
                        print("get details error \(task.error)")
                        observer.send(error: .failed)
                    } else {
                        self.username = username
                        self.password = password
                        self.email = !username.hasPrefix("fb_") ? username : ""
                        print("task.result mfa = \(task.result?.mfaOptions), attrs = \(task.result?.userAttributes)")
                        for attr in (task.result?.userAttributes)! {
                            print("has attr for name \(attr.name)")
                            if attr.name == "name" {
                                #if CUSTOMER
                                    self.name = attr.value
                                #endif
                            } else if attr.name == "custom:phone" {
                                #if CUSTOMER
                                    self.phone = attr.value
                                #endif
                            } else if attr.name == "custom:fb_email" {
                                self.email = attr.value
                            }
                        }
                        
                        #if MERCHANT
                            Api.merchants.auth(email: username).observeValues { [unowned self] in
                                if let merchantUser: MerchantUser = $0 {
                                    self.merchantUser = merchantUser
                                    observer.send(value: ())
                                } else {
                                    self.username = nil
                                    self.password = nil
                                    self.email = nil
                                    observer.send(error: .failed)
                                }
                            }
                        #else
                            observer.send(value: ())
                        #endif
                    }
                    
                    return nil
                })
            }
            
            return nil
        })
        
        return signal
    }
    
    func changePassword(from: String, to: String) -> Signal<Void, AuthError> {
        let (signal, observer) = Signal<Void, AuthError>.pipe()
        let task = user.changePassword(from, proposedPassword: to)
        
        task.continue( { [unowned self] (task: AWSTask<AWSCognitoIdentityUserChangePasswordResponse>) -> Any? in
            if task.error != nil {
                observer.send(error: .failed)
            } else {
                self.password = to
                observer.send(value: ())
            }
            
            return nil
        })
        
        return signal
    }
    
    func forgotPassword(email: String) -> Signal<String, AuthError> {
        let (signal, observer) = Signal<String, AuthError>.pipe()
        let task = pool.getUser(email.lowercased()).forgotPassword()
        
        task.continue( { (task: AWSTask<AWSCognitoIdentityUserForgotPasswordResponse>) -> Any? in
            if task.error != nil {
                observer.send(error: .failed)
            } else {
                observer.send(value: (task.result?.codeDeliveryDetails?.destination)!)
            }
            
            return nil
        })
        
        return signal
    }
    
    func restorePassword(email: String, code: String, password: String) -> Signal<Void, AuthError> {
        let email = email.lowercased()
        
        let (signal, observer) = Signal<Void, AuthError>.pipe()
        let task = pool.getUser(email).confirmForgotPassword(code, password: password)
        
        task.continue( { [unowned self] (task: AWSTask<AWSCognitoIdentityUserConfirmForgotPasswordResponse>) -> Any? in
            if task.error != nil {
                observer.send(error: .failed)
            } else {
                self.username = email
                self.password = password
                
                self.signIn(username: email, password: password)
                    .observe {
                        if let error: AuthError = $0.error {
                            observer.send(error: error)
                        } else {
                            observer.send(value: ())
                        }
                }
            }
            
            return nil
        })
        
        return signal
    }
    
    #if CUSTOMER
    
    func signUp(email: String, password: String, name: String) -> Signal<Void, AuthError> {
        let (signal, observer) = Signal<Void, AuthError>.pipe()
        let task = pool.signUp(email.lowercased(),
                               password: password,
                               userAttributes: [
                                AWSCognitoIdentityUserAttributeType(name: "email", value: email),
                                AWSCognitoIdentityUserAttributeType(name: "name", value: name)
                                ],
                               validationData: nil)
        
        task.continue( { [unowned self] (task: AWSTask<AWSCognitoIdentityUserPoolSignUpResponse>) -> Any? in
            if task.error != nil {
                observer.send(error: .failed)
            } else {
                self.username = email.lowercased()
                self.email = email
                self.password = password
                self.name = name
                
                let result = task.result
                if result?.user.confirmedStatus != .confirmed {
                    observer.send(error: .requiresConfirm)
                } else {
                    observer.send(value: ())
                }
            }
            
            return nil
        })
        
        return signal
    }
    
    func resendConfirmationCode(email: String) -> Signal<Void, AuthError>  {
        let (signal, observer) = Signal<Void, AuthError>.pipe()
        let task = pool.getUser(email.lowercased()).resendConfirmationCode()
        
        task.continue( { (task: AWSTask<AWSCognitoIdentityUserResendConfirmationCodeResponse>) -> Any? in
            if task.error != nil {
                observer.send(error: .failed)
            } else {
                observer.send(value: ())
            }
            
            return nil
        })
        
        return signal
    }
    
    func confirmRegistration(email: String, code: String) -> Signal<Void, AuthError>  {
        let (signal, observer) = Signal<Void, AuthError>.pipe()
        let task = pool.getUser(email.lowercased()).confirmSignUp(code, forceAliasCreation: true)
        
        task.continue( { (task: AWSTask<AWSCognitoIdentityUserConfirmSignUpResponse>) -> Any? in
            if task.error != nil {
                observer.send(error: .failed)
            } else {
                observer.send(value: ())
            }
            
            return nil
        })
        
        return signal
    }
    
    private func signUpFacebook(username: String, password: String,
                                name: String) -> Signal<Void, AuthError> {
        let (signal, observer) = Signal<Void, AuthError>.pipe()
        let task = pool.signUp(username,
                               password: password,
                               userAttributes: [
                                AWSCognitoIdentityUserAttributeType(name: "name", value: name),
                                AWSCognitoIdentityUserAttributeType(name: "custom:is_facebook", value: "1")],
                               validationData: nil)
        
        task.continue( { [unowned self] (task: AWSTask<AWSCognitoIdentityUserPoolSignUpResponse>) -> Any? in
            if task.error != nil {
                observer.send(error: .failed)
            } else {
                self.username = username
                self.password = password
                self.name = name
                observer.send(value: ())
            }
            
            return nil
        })
        
        return signal
    }
    
    func authFacebook(from vc: UIViewController) -> Signal<Void, AuthError> {
        let (signal, observer) = Signal<Void, AuthError>.pipe()
    
        let manager = FBSDKLoginManager()
        manager.logIn(withReadPermissions: ["public_profile","email"],
                      from: vc) { (result: FBSDKLoginManagerLoginResult?, error: Error?) in
            print("[Facebook Auth] error = \(error), result = \(result)")
            if error != nil || (result?.isCancelled)! {
                observer.send(error: .failed)
            } else {
                FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"id,name"])
                    .start(completionHandler: { [unowned self]
                        (connection: FBSDKGraphRequestConnection?, result: Any?, error: Error?) in
//                        print("[Facebook Auth] /me error = \(error), result = \(result)")
//                        if error != nil {
//                            observer.send(error: .failed)
//                        } else {
//                            if let response: Dictionary<String, Any> = result as! Dictionary? {
//                                if let name: String = response["name"] as! String? {
//                                    self.name = name
//                                } else {
//                                    self.name = nil
//                                }
//                                observer.send(value: ())
//                            } else {
//                                observer.send(error: .failed)
//                            }
//                        }
                        
                        print("[Facebook Auth] /me error = \(error), result = \(result)")
                        
                        if error != nil {
                            observer.send(error: .failed)
                        } else {
                            if let response: Dictionary<String, Any> = result as! Dictionary? {
                                let salt = "8d5fe4011a345782535d9f031af133aa"
                                let username = "fb_\(response["id"]!)"
                                let password = "\(username)_\(salt)".sha256()
                                print("[Facebook Auth] username = \(username), password = \(password)")
                                
                                self.signIn(username: username, password: password!).observe { [unowned self] in
                                    if let _ = $0.error {
//                                        print("error requires confirm = \(error == .requiresConfirm)")
//                                        if error == .failed { // user doesn't exist
                                            let name = response["name"] ?? ""
                                            print("[Facebook Auth] name = \(name)")
                                            self.signUpFacebook(username: username, password: password!,
                                                name: name as! String).observe {
    
                                                print("[Facebook Auth] sign up error = \($0.error)")
                                                if $0.error != nil {
                                                    observer.send(error: .failed)
                                                } else {
                                                    observer.send(value: ())
                                                }
                                            }
//                                        }
                                    } else {
                                        print("[Facebook Auth] sign in no error")
                                        observer.send(value: ())
                                    }
                                }
                            } else {
                                observer.send(error: .failed)
                            }
                        }
                })
            }
        }
        
        return signal
    }
    
    #endif
    
    #if MERCHANT
    
    func remove(pushToken: String) {
        if let merchant: Merchant = Api.auth.merchantUser.merchant,
            merchant.iOSPushTokens.contains(pushToken) {
            merchant.iOSPushTokens = merchant.iOSPushTokens.filter { $0 != pushToken }
            merchant.prepareForSave()
            
            AWS.objectMapper.save(merchant).continue({ (task: AWSTask<AnyObject>) -> Any? in
                return nil
            })
        }
    }
    
    func set(pushToken: String) {
        if let merchant: Merchant = Api.auth.merchantUser.merchant,
            !merchant.iOSPushTokens.contains(pushToken) {
            merchant.iOSPushTokens.append(pushToken)
            merchant.prepareForSave()
            
            let expr = AWSDynamoDBScanExpression()
            expr.filterExpression = "contains(iOSPushTokensJSONArrayString, :pushToken)"
            expr.expressionAttributeValues = [":pushToken":pushToken]
            
            AWS.objectMapper.scan(Merchant.self, expression: expr)
                .continue({ (task: AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
                    if let merchants: [Merchant] = task.result?.items as! [Merchant]? {
                        for m in merchants {
                            m.iOSPushTokens = merchant.iOSPushTokens.filter { $0 != pushToken }
                            m.prepareForSave()
                            AWS.objectMapper.save(m).continue({ (task: AWSTask<AnyObject>) -> Any? in
                                return nil
                            })
                        }
                    }
                    
                    AWS.objectMapper.save(merchant).continue({ (task: AWSTask<AnyObject>) -> Any? in
                        return nil
                    })
                    
                    return nil
                })
        }
    }
    
    func replace(pushToken: String, with newToken: String) {
        
        if let merchant: Merchant = Api.auth.merchantUser.merchant,
            !merchant.iOSPushTokens.contains(newToken) {
            
            if merchant.iOSPushTokens.contains(pushToken) {
                merchant.iOSPushTokens = merchant.iOSPushTokens.filter { $0 != pushToken }
            }
            
            merchant.iOSPushTokens.append(newToken)
            merchant.prepareForSave()
            
            let expr = AWSDynamoDBScanExpression()
            expr.filterExpression = "contains(iOSPushTokensJSONArrayString, :pushToken)"
            expr.expressionAttributeValues = [":pushToken":pushToken]
            
            AWS.objectMapper.scan(Merchant.self, expression: expr)
                .continue({ (task: AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
                    if let merchants: [Merchant] = task.result?.items as! [Merchant]? {
                        for m in merchants {
                            m.iOSPushTokens = merchant.iOSPushTokens.filter { $0 != pushToken }
                            m.prepareForSave()
                            AWS.objectMapper.save(m).continue({ (task: AWSTask<AnyObject>) -> Any? in
                                return nil
                            })
                        }
                    }
                    
                    AWS.objectMapper.save(merchant).continue({ (task: AWSTask<AnyObject>) -> Any? in
                        return nil
                    })
                    
                    return nil
                })
        } else {
            if merchantUser.merchant.iOSPushTokens.contains(pushToken) {
                merchantUser.merchant.iOSPushTokens = merchantUser.merchant.iOSPushTokens.filter { $0 != pushToken }
                
                merchantUser.merchant.prepareForSave()
                AWS.objectMapper.save(merchantUser.merchant).continue({ (task: AWSTask<AnyObject>) -> Any? in
                    return nil
                })
            }
        }
    }
    #endif
}
