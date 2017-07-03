//
//  EncryptedStorage.swift
//  YQueue
//
//  Created by Aleksandr on 21/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit

class EncryptedStorage: NSObject {

    private var name: String
    
    init(name: String) {
        self.name = name
        super.init()
        
        let dirPath = documentsDirectory.appendingPathComponent("encstorage/")
        if !FileManager.default.fileExists(atPath: dirPath.path) {
            try! FileManager.default.createDirectory(at: dirPath,
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)
        }
    }
    
    private lazy var documentsDirectory: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }()
    
    public func load() -> Any? {
        let filePath = documentsDirectory
            .appendingPathComponent("encstorage/")
            .appendingPathComponent(name.md5())
        print("filepath = \(filePath)")
        
        do {
            let data = try Data(contentsOf: filePath, options: Data.ReadingOptions())
            guard let base64Decoded: Data = Data(base64Encoded: data,
                                                 options: .ignoreUnknownCharacters) else {
                                                    return nil
            }
            
            guard let decrypted: Data = Encryption.decrypt(data: base64Decoded) else {
                return nil
            }
            
            let object = try JSONSerialization.jsonObject(with: decrypted,
                                                          options: JSONSerialization.ReadingOptions())
            return object
        } catch (_) {
            return nil
        }
    }
    
    public func save(_ object: Any) {
        let filePath = documentsDirectory
            .appendingPathComponent("encstorage/")
            .appendingPathComponent(name.md5())
        
        do {
            let data = try JSONSerialization.data(withJSONObject: object,
                                                  options: JSONSerialization.WritingOptions())
            
            guard let encrypted: Data = Encryption.encrypt(data: data) else {
                return
            }
            
            let base64Encoded: Data = encrypted.base64EncodedData()
            
            try base64Encoded.write(to: filePath, options: Data.WritingOptions())
        } catch (_) {
        }
    }
    
    public class Encryption {
        private static let key = "eb24d129fb9ad62608027b85747e214d"
        
        public static func encrypt(data: Data) -> Data? {
            var keyPtr = Array<CChar>(repeating: CChar(0), count: kCCKeySizeAES256 + 1)
            _ = key.getCString(&keyPtr,
                               maxLength: kCCKeySizeAES256 + 1,
                               encoding: .utf8)
            
            let bufferSize = data.count + kCCBlockSizeAES128
            let buffer: UnsafeMutableRawPointer = malloc(bufferSize)
            
            var numBytesDecrypted: size_t = 0
            let status = CCCrypt(CCOperation(kCCEncrypt),
                                 CCAlgorithm(kCCAlgorithmAES),
                                 CCOptions(kCCOptionPKCS7Padding),
                                 keyPtr,
                                 kCCKeySizeAES256,
                                 nil, [UInt8](data), data.count, buffer, bufferSize, &numBytesDecrypted)
            if status == CCCryptorStatus(kCCSuccess) {
                return Data.init(bytesNoCopy: buffer, count: numBytesDecrypted, deallocator: .none)
            }
            
            free(buffer);
            return nil;
        }
        
        public static func decrypt(data: Data) -> Data? {
            var keyPtr = Array<CChar>(repeating: CChar(0), count: kCCKeySizeAES256 + 1)
            _ = key.getCString(&keyPtr,
                               maxLength: kCCKeySizeAES256 + 1,
                               encoding: .utf8)
            
            let bufferSize = data.count + kCCBlockSizeAES128
            let buffer: UnsafeMutableRawPointer = malloc(bufferSize)
            
            var numBytesDecrypted: size_t = 0
            let status = CCCrypt(CCOperation(kCCDecrypt),
                                 CCAlgorithm(kCCAlgorithmAES),
                                 CCOptions(kCCOptionPKCS7Padding),
                                 keyPtr,
                                 kCCKeySizeAES256,
                                 nil, [UInt8](data), data.count, buffer, bufferSize, &numBytesDecrypted)
            if status == CCCryptorStatus(kCCSuccess) {
                return Data.init(bytesNoCopy: buffer, count: numBytesDecrypted, deallocator: .none)
            }
            
            free(buffer)
            return nil
        }
    }
}
