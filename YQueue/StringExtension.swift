//
//  StringExtension.swift
//  YQueue
//
//  Created by Toshio on 03/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import Foundation

extension String {
    
    var workingTime: Int {
        if !contains(":") {
            return 0
        }
        
        let hoursString: String = components(separatedBy: ":")[0]
        if hoursString != hoursString.onlyDigits || hoursString.characters.count != 2 {
            return 0
        }
        
        let minutesString: String = components(separatedBy: ":")[1]
        if minutesString != minutesString.onlyDigits || minutesString.characters.count != 2 {
            return 0
        }
        
        let hours: Int = Int(hoursString)!
        if hours < 0 || hours > 24 {
            return 0
        }
        
        let minutes: Int = Int(minutesString)!
        if minutes < 0 || minutes > 59 {
            return 0
        }
        
        return hours*60 + minutes
    }
    
    var isValidEmail: Bool {
        do {
            let regex = try
                NSRegularExpression(pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
                                    options: .caseInsensitive)
            return regex.firstMatch(in: self,
                                    options: NSRegularExpression.MatchingOptions(),
                                    range: NSMakeRange(0, self.characters.count)) != nil
        } catch _ {
            return false
        }
    }
    
    var onlyDigits: String {
        return components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
    }
    
    var priceDigits: String {
        var charset = CharacterSet.decimalDigits
        charset.insert(".")
        charset = charset.inverted
        return components(separatedBy: charset).joined(separator: "")
    }
    
    func sha256(usingInitialValueOnFail: Bool) -> String? {
        guard
            let data = self.data(using: String.Encoding.utf8),
            let shaData = data.sha256()
            else { return usingInitialValueOnFail ? self : nil }
        let rc = shaData.base64EncodedString(options: [])
        return rc
    }
    
    func sha256() -> String? {
        return sha256(usingInitialValueOnFail: false)
    }
    
    func md5() -> String {
        guard let messageData = data(using: .utf8) else {
            return self
        }
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes { digestBytes in
            messageData.withUnsafeBytes { messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        
        return String(data: digestData, encoding: .utf8) ?? self
    }
    
    func limit(_ length: Int) -> String {
        return
            characters.count > length ?
                substring(to: self.index(self.startIndex, offsetBy: length)) :
                self;
    }
    
    static func repeatedCharacter(char: Character, length: Int) -> String {
        var str = ""
        for _ in 1...length {
            str.append(char)
        }
        return str
    }
}
