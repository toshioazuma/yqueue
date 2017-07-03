//
//  AWS.swift
//  YQueue
//
//  Created by Aleksandr on 21/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import AWSCore
import AWSCognito
import AWSCognitoIdentityProvider
import AWSDynamoDB
import AWSS3
import AWSSNS
import AWSSES

class AWS: NSObject {

    static let emptyString = "AWS_NO_VALUE"
    
    #if MERCHANT
    static let clientId = "1kabqvf4v3hr1v9uling1tg0se"
    static let clientSecret = "rq72geiqtrfbvq35uu88lu9piafara4qt8p91oot65eugcm8uja"
    static let poolId = "ap-northeast-1_AZFuVxuL5"
    #else
    static let clientId = "5vt4i170k78o449vl86i50g22s"
    static let clientSecret = "u6jq0jsmn06oa3s2ijsstur8kdf0spk96ttmvrm3mt36vihijhf"
    static let poolId = "ap-northeast-1_Ao3ubBvYn"
    #endif
    
    static let identityPoolId = "ap-northeast-1:1f55b10a-8572-4013-893f-7f02db67fe1f"
    
    static let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .apNortheast1,
                                                                   identityPoolId: identityPoolId)
    static let serviceConfig = AWSServiceConfiguration(region: .apNortheast1,
                                                       credentialsProvider: credentialsProvider)
//    static let storageBucket = "yqueue-userfiles-mobilehub-1226121923"
    static let storageBucket = "yqueue"
    
    static let pool: AWSCognitoIdentityUserPool = {
        AWSLogger.default().logLevel = AWSLogLevel.verbose
        AWSServiceManager.default().defaultServiceConfiguration = serviceConfig
        
        let config = AWSCognitoIdentityUserPoolConfiguration(clientId: clientId,
                                                             clientSecret: clientSecret,
                                                             poolId: poolId)
        AWSCognitoIdentityUserPool.register(with: serviceConfig,
                                            userPoolConfiguration: config,
                                            forKey: "UserPool")
        return AWSCognitoIdentityUserPool(forKey: "UserPool")
    }()
    
    static let dynamoDB: AWSDynamoDB = {
        AWSServiceManager.default().defaultServiceConfiguration = serviceConfig
        
        AWSDynamoDB.register(with: serviceConfig!, forKey: "DynamoDB")
        return AWSDynamoDB.init(forKey: "DynamoDB")
    }()
    
    static let objectMapper: AWSDynamoDBObjectMapper = {
        AWSServiceManager.default().defaultServiceConfiguration = serviceConfig
        
        let config = AWSDynamoDBObjectMapperConfiguration()
        AWSDynamoDBObjectMapper.register(with: serviceConfig!,
                                         objectMapperConfiguration: config,
                                         forKey: "DynamoDBObjectMapper")
        return AWSDynamoDBObjectMapper(forKey: "DynamoDBObjectMapper")
    }()
    
    static let storage: AWSS3 = {
        AWSServiceManager.default().defaultServiceConfiguration = serviceConfig
        
        AWSS3.register(with: serviceConfig!, forKey: "S3Storage")
        return AWSS3.s3(forKey: "S3Storage")
    }()
    
    static let storageUtility: AWSS3TransferUtility = {
        AWSServiceManager.default().defaultServiceConfiguration = serviceConfig
        
        AWSS3TransferUtility.register(with: serviceConfig!, transferUtilityConfiguration: AWSS3TransferUtilityConfiguration(), forKey: "S3StorageUtility")
        return AWSS3TransferUtility.s3TransferUtility(forKey: "S3StorageUtility")
    }()
    
    static let sns: AWSSNS = {
        AWSServiceManager.default().defaultServiceConfiguration = serviceConfig
        
        AWSSNS.register(with: serviceConfig!, forKey: "SNS")
        return AWSSNS(forKey: "SNS")
    }()
    
    static let ses: AWSSES = {
        
         let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .euWest1,
                                                                       identityPoolId: identityPoolId)
         let serviceConfig = AWSServiceConfiguration(region: .euWest1,
                                                           credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = serviceConfig
        
        AWSSES.register(with: serviceConfig!, forKey: "SES")
        return AWSSES(forKey: "SES")
    }()
    
    static let silentBlock = { (task: AWSTask<AnyObject>) -> Any? in
        return nil
    }
    
    static func send(emailTo recipientEmail: String, subject: String, body: String) {
        let to: AWSSESDestination = AWSSESDestination()
        to.toAddresses = [recipientEmail]
        
        let bodyTextObject: AWSSESContent = AWSSESContent()
        bodyTextObject.charset = "utf-8"
        bodyTextObject.data = body
        
        let bodyObject: AWSSESBody = AWSSESBody()
        bodyObject.text = bodyTextObject
        
        let subjectObject: AWSSESContent = AWSSESContent()
        subjectObject.charset = "utf-8"
        subjectObject.data = subject
        
        let messageObject: AWSSESMessage = AWSSESMessage()
        messageObject.body = bodyObject
        messageObject.subject = subjectObject
        
        let request: AWSSESSendEmailRequest = AWSSESSendEmailRequest()
        request.source = "no-reply@yqueue.tech"
        request.destination = to
        request.message = messageObject
        ses.sendEmail(request).continue( { (task: AWSTask<AWSSESSendEmailResponse>) -> Any? in
            print("send email error = \(task.error)")
            return nil
        })
    }
    
    static func test() {
        
        let request: AWSSESSendEmailRequest = AWSSESSendEmailRequest()
        
        let to: AWSSESDestination = AWSSESDestination()
        to.toAddresses = ["posplaw@gmail.com"]
        request.destination = to
        
        let message: AWSSESMessage = AWSSESMessage()
        let body: AWSSESBody = AWSSESBody()
        let bodyText: AWSSESContent = AWSSESContent()
        bodyText.charset = "utf-8"
        bodyText.data = "Test message"
        body.text = bodyText
        message.body = body
        let subject: AWSSESContent = AWSSESContent()
        subject.charset = "utf-8"
        subject.data = "Test e-mail"
        message.subject = subject
        
        request.source = "no-reply@yqueue.tech"
        request.message = message
        ses.sendEmail(request).continue( { (task: AWSTask<AWSSESSendEmailResponse>) -> Any? in
            print("send email error = \(task.error)")
            return nil
        })
    }
}

extension String {
    var aws: String {
        get {
            return self == AWS.emptyString ? "" : self
        }
    }
}
