//
//  DataExtension.swift
//  YQueue
//
//  Created by Toshio on 06/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import Foundation

extension Data {
    
    var hexRepresentation: String {
        var token: String = ""
        for i in 0..<self.count {
            token += String(format: "%02.2hhx", self[i] as CVarArg)
        }
        
        return token
    }
    
    func sha256() -> Data? {
        guard let res = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH)) else { return nil }
        CC_SHA256((self as NSData).bytes,
                  CC_LONG(self.count),
                  res.mutableBytes.assumingMemoryBound(to: UInt8.self))
        return res as Data
    }
}
