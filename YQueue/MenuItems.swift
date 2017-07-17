//
//  MenuItems.swift
//  YQueue
//
//  Created by Toshio on 24/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import AWSDynamoDB
import AWSS3
import ReactiveCocoa
import ReactiveSwift
import Result

class MenuItems: NSObject {
    
    func list(for category: MenuCategory) -> Signal<[MenuItem], NoError> {
        let (signal, observer) = Signal<[MenuItem], NoError>.pipe()
        
        let expr = AWSDynamoDBQueryExpression()
        expr.keyConditionExpression = "categoryId = :categoryId"
        expr.expressionAttributeValues = [":categoryId":category.id]
        
        AWS.objectMapper.query(MenuItem.self, expression: expr).continue( { (task: AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
            var menuItems = Array<MenuItem>()
            if task.error == nil {
                for menuItem: MenuItem in task.result?.items as! [MenuItem] {
                    menuItem.category = category
                    menuItems.append(menuItem)
                }
            }
            observer.send(value: menuItems)
            
            return nil
        })
        
        return signal
    }
    
    #if CUSTOMER
    
    func specialOffers(for merchant: Merchant) -> Signal<[String], NoError> {
        let (signal, observer) = Signal<[String], NoError>.pipe()
        
        OperationQueue().addOperation {
            // ensure to be in background thread since using synchronous requests
            
            var specialOffers = [String]()
            // special offers asked only after retrieval of menu categories
            // then we're welcome to use local values
            if let menuCategories: [MenuCategory] = merchant.menuCategories {
                for menuCategory in menuCategories {
                    let expr = AWSDynamoDBQueryExpression()
                    expr.keyConditionExpression = "categoryId = :categoryId"
                    expr.filterExpression = "not(specialOfferText = :emptyString)"
                    expr.expressionAttributeValues = [":categoryId" : menuCategory.id,
                                                      ":emptyString" : AWS.emptyString]
                    
                    AWS.objectMapper.query(MenuItem.self, expression: expr).continue( { (task: AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
                        if task.error == nil {
                            for menuItem: MenuItem in task.result?.items as! [MenuItem] {
                                specialOffers.append(menuItem.specialOfferText)
                            }
                        }
                        
                        return nil
                    }).waitUntilFinished()
                }
            }
            observer.send(value: specialOffers)
        }
    
        return signal
    }
    
    #endif
    
    
    enum MenuItemByIdError: Error {
        case failed
    }
    
//    private func byId(_ number: String, categories: [MenuCategory]) -> Signal<MenuItem?, MenuItemByIdError> {
//        let (signal, observer) = Signal<MenuItem?, MenuItemByIdError>.pipe()
//        
//        let category = categories[0]
//        let expr = AWSDynamoDBQueryExpression()
//        expr.keyConditionExpression = "categoryId = :categoryId"
//        expr.filterExpression = "numberForSearch = :number"
////        expr.expressionAttributeNames = ["#number":"number"]
//        expr.expressionAttributeValues = [":categoryId":category.id,
//                                          ":number":number.lowercased()]
//        
//        AWS.objectMapper.query(MenuItem.self, expression: expr).continue( { (task: AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
//            if task.error != nil {
//                observer.send(error: .failed)
//            } else if task.result?.items.count == 0 {
//                var categories = categories
//                categories.remove(at: 0)
//                
//                if categories.count == 0 {
//                    observer.send(value: nil)
//                } else {
//                    self.byId(number, categories: categories).observe {
//                        if $0.error != nil {
//                            observer.send(error: .failed)
//                        } else if let menuItem: MenuItem = $0.value! {
//                            observer.send(value: menuItem)
//                        } else {
//                            observer.send(value: nil)
//                        }
//                    }
//                }
//            } else {
//                var menuItems = Array<MenuItem>()
//                for menuItem: MenuItem in task.result?.items as! [MenuItem] {
//                    menuItem.category = category
//                    menuItems.append(menuItem)
//                }
//                observer.send(value: menuItems[0])
//            }
//            
//            return nil
//        })
//        
//        return signal
//    }
    
    func byId(_ number: String, merchant: Merchant) -> Signal<MenuItem?, MenuItemByIdError> {
        let (signal, observer) = Signal<MenuItem?, MenuItemByIdError>.pipe()
        
        let expr = AWSDynamoDBQueryExpression()
        expr.indexName = "numberForSearch-index"
        expr.scanIndexForward = NSNumber(booleanLiteral: true)
        expr.keyConditionExpression = "numberForSearch = :number"
        expr.filterExpression = "merchantId = :merchantId"
        expr.expressionAttributeValues = [":number" : number.lowercased(), ":merchantId" : merchant.id]
        
        AWS.objectMapper.query(MenuItem.self, expression: expr).continue( { (task: AWSTask<AWSDynamoDBPaginatedOutput>) -> Any? in
            if task.error != nil {
                observer.send(error: .failed)
            } else if task.result?.items.count == 0 {
                observer.send(value: nil)
            } else {
                for menuItem: MenuItem in task.result?.items as! [MenuItem] {
                    var found = false
                    for menuCategory in merchant.menuCategories {
                        if menuCategory.id == menuItem.categoryId {
                            menuItem.category = menuCategory
                            found = true
                            break
                        }
                    }
                    
                    if found {
                        observer.send(value: menuItem)
                    } else {
                        AWS.objectMapper.load(MenuCategory.self,
                                              hashKey: merchant.id,
                                              rangeKey: menuItem.categoryId)
                            .continue({ (task: AWSTask<AnyObject>) -> Any? in
                                menuItem.category = task.result as! MenuCategory!
                                menuItem.category.merchant = merchant
                                observer.send(value: menuItem)
                                return nil
                            })
                    }
                    break
                }
            }
            
            return nil
        })
        
//        numberForSearch-index

        
//        let searchBlock = { (categories: [MenuCategory]) -> Void in
//            if categories.count == 0 {
//                OperationQueue.main.addOperation {
//                    observer.send(value: nil)
//                }
//            } else {
//                self.byId(number, categories: categories).observe {
//                    if $0.error != nil {
//                        observer.send(error: .failed)
//                    } else {
//                        observer.send(value: $0.value!)
//                    }
//                }
//            }
//        }
//        
        // check if categories already loaded, otherwise fetch them
//        if let categories: [MenuCategory] = merchant.menuCategories {
//            searchBlock(categories)
//        } else {
//            Api.menuCategories.list(for: merchant).observeValues {
//                if let categories: [MenuCategory] = $0 {
//                    searchBlock(categories)
//                } else {
//                    searchBlock([])
//                }
//            }
//        }
//        
        
        return signal
    }
    
    private lazy var documentsDirectory: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }()
    
    func download(_  photo: MenuItem.Photo, for item: MenuItem) -> Signal<UIImage?, NoError> {
        let (signal, observer) = Signal<UIImage?, NoError>.pipe()
        
        var image: UIImage?
        
        let path = "merchants/\((item.category.merchant.id)!)/\(photo.name).jpg"
//        let path = "merchants/\((item.category.merchant.id)!)/\((item.category.id)!)/\(photo.name).jpg"
        let localPath = documentsDirectory.appendingPathComponent(path)
        do {
            let localData = try Data(contentsOf: localPath, options: Data.ReadingOptions())
            image = UIImage(data: localData)
        } catch (_) {
            print("Couldn't read from '\(localPath)'")
        }
    
        if image != nil {
            OperationQueue.main.addOperation {
                observer.send(value: image)
            }
        } else {
            AWS.storageUtility.downloadData(fromBucket: AWS.storageBucket,
                                            key: path,
                                            expression: nil,
                                            completionHander: {
                                                (_, _, data: Data?, error: Error?) in
                                                if let data: Data = data,
                                                    let image: UIImage = UIImage(data: data) {
                                                    OperationQueue().addOperation {
                                                        do {
                                                            try FileManager.default.createDirectory(at: localPath.deletingLastPathComponent(),
                                                                                                    withIntermediateDirectories: true,
                                                                                                    attributes: nil)
                                                            try data.write(to: localPath)
                                                        } catch (_) {
                                                            print("couldn't write file")
                                                        }
                                                    }
                                                    
                                                    observer.send(value: image)
                                                } else {
                                                    observer.send(value: nil)
                                                }
            }).continue( { (task: AWSTask<AWSS3TransferUtilityDownloadTask>) -> Any? in
                return nil
            })
        }
        
        return signal
    }
    
    #if MERCHANT
    
    func delete(_ menuItem: MenuItem) -> Signal<Bool, NoError> {
        let (signal, observer) = Signal<Bool, NoError>.pipe()
        
        AWS.objectMapper.remove(menuItem).continue( { (task: AWSTask<AnyObject>) -> Any? in
            if task.error != nil {
                observer.send(value: false)
            } else {
                if menuItem.photos.count > 0 {
                    self.delete(photos: menuItem.photos, for: menuItem).observeValues {
                        observer.send(value: $0)
                    }
                } else {
                    observer.send(value: true)
                }
            }
            
            return nil
        })
    
        return signal
    }
    
    enum MenuItemSaveError: Error {
        case failed, couldntRemoveFromCurrentCategory, idDuplicate
    }
    
    func save(_ menuItem: MenuItem, oldCategoryId: String?, newItemNumber: String?) -> Signal<Void, MenuItemSaveError> {
        let (signal, observer) = Signal<Void, MenuItemSaveError>.pipe()
        
        let save: () -> Void = {
            AWS.objectMapper.save(menuItem).continue( { (task: AWSTask<AnyObject>) -> Any? in
                if task.error != nil {
                    print("menu item save error = \(task.error)")
                    observer.send(error: .failed)
                } else {
                    if let oldCategoryId: String = oldCategoryId {
                        let oldMenuItem = MenuItem()
                        oldMenuItem?.categoryId = oldCategoryId
                        oldMenuItem?.id = menuItem.id
                        
                        self.delete(oldMenuItem!).observe {
                            if $0.value! {
                                observer.send(value: ())
                            } else {
                                observer.send(error: .couldntRemoveFromCurrentCategory)
                            }
                        }
                        
                    } else {
                        observer.send(value: ())
                    }
                }
                
                return nil
            })
        };
        
        if newItemNumber != nil {
            byId(menuItem.number, merchant: Api.auth.merchantUser.merchant).observe {
                print("same number error = \($0.error), obj = \($0.value)")
                if $0.error != nil {
                    observer.send(error: .failed)
                } else if $0.value! != nil {
                    observer.send(error: .idDuplicate)
                } else {
                    save()
                }
            }
        } else {
            save()
        }
        
        return signal
    }
    
//    func copy(photos: [MenuItem.Photo], for item: MenuItem, oldCategoryId: String) -> Signal<Bool, NoError> {
//        assert(photos.count > 0, "Can't copy empty array of photos")
//        
//        let (signal, observer) = Signal<Bool, NoError>.pipe()
//        
//        copy(photo: photos[0], for: item, oldCategoryId: oldCategoryId).observe {
//            if !$0.value! {
//                observer.send(value: false)
//            } else {
//                var photos = photos
//                photos.removeFirst()
//                
//                if photos.count > 0 {
//                    self.copy(photos: photos, for: item, oldCategoryId: oldCategoryId).observe {
//                        if !$0.value! {
//                            observer.send(value: false)
//                        } else {
//                            observer.send(value: true)
//                        }
//                    }
//                } else {
//                    observer.send(value: true)
//                }
//            }
//        }
//
//        
//        return signal
//    }
//    
//    func copy(photo: MenuItem.Photo, for item: MenuItem, oldCategoryId: String) -> Signal<Bool, NoError> {
//        let (signal, observer) = Signal<Bool, NoError>.pipe()
//        
//        let oldPath = "\(AWS.storageBucket)/merchants/\((item.category.merchant.id)!)/\(oldCategoryId)/\(photo.name).jpg"
//        let newPath = "merchants/\((item.category.merchant.id)!)/\((item.category.id)!)/\(photo.name).jpg"
//        let request: AWSS3ReplicateObjectRequest = AWSS3ReplicateObjectRequest()
//        request.bucket = AWS.storageBucket
//        request.key = newPath
//        request.replicateSource = oldPath
//        
//        AWS.storage.replicateObject(request).continue( { (task: AWSTask<AWSS3ReplicateObjectOutput>) -> Any? in
//            observer.send(value: task.error == nil)
//            
//            return nil
//        })
//        
//        return signal
//    }
    
    func upload(photos: [MenuItem.Photo], for item: MenuItem) -> Signal<Bool, NoError> {
        assert(photos.count > 0, "Can't upload empty array of photos")
        
        let (signal, observer) = Signal<Bool, NoError>.pipe()
        
        // upload first photo
        print("trying to upload photo from array of \(photos.count) photos")
        upload(photo: photos[0], for: item).observe {
            print("upload first photo result = \($0)")
            if !$0.value! {
                print("couldn't upload it, send error")
                observer.send(value: false)
            } else {
                // go to next photo
                var photos = photos
                photos.removeFirst()
                print("successfully uploaded photo, removed it from list, now photos left = \(photos.count)")
                
                // there can be entered in deeper enters
                if photos.count > 0 {
                    print("some photos left, let's go with next")
                    self.upload(photos: photos, for: item).observe {
                        if !$0.value! {
                            // return back it's failed
                            observer.send(value: false)
                        } else {
                            // return back this chain suceeded
                            observer.send(value: true)
                        }
                    }
                } else {
                    print("yup, no photos left, send true")
                    // final photo, send true
                    observer.send(value: true)
                }
            }
        }
        
        
        return signal
    }
    
    func upload(photo: MenuItem.Photo, for item: MenuItem) -> Signal<Bool, NoError> {
        let (signal, observer) = Signal<Bool, NoError>.pipe()

        let path = "merchants/\((item.category.merchant.id)!)/\(photo.name).jpg"
//        let path = "merchants/\((item.category.merchant.id)!)/\((item.category.id)!)/\(photo.name).jpg"
        AWS.storageUtility.uploadData(UIImageJPEGRepresentation(photo.image.value!, 0.6)!,
                                      bucket: AWS.storageBucket,
                                      key: path,
                                      contentType: "image/jpeg",
                                      expression: nil,
                                      completionHander: nil).continue({ (task: AWSTask<AWSS3TransferUtilityUploadTask>) -> Any? in
                                        print("photo upload error = \(task.error)")
                                        print("photo upload result = \(task.result)")
                                        observer.send(value: task.error == nil)
                                        
                                        return nil
                                      })
        
//        let request = AWSS3PutObjectRequest()
//        request?.bucket = AWS.storageBucket
//        request?.key = path
//        request?.contentType = "image/jpeg"
//        request?.body = UIImageJPEGRepresentation(photo.image.value!, 0.6)
//        print("request body length = \(UIImageJPEGRepresentation(photo.image.value!, 0.6)?.count)")
//        
//        AWS.storage.putObject(request!).continue({ (task: AWSTask<AWSS3PutObjectOutput>) -> Any? in
//            print("photo upload error = \(task.error)")
//            print("photo upload result = \(task.result)")
//            observer.send(value: task.error == nil)
//            return nil
//        })
//        print("request is \(request)")
//        AWS.storage.upload(request).continue( { (task: AWSTask<AnyObject>) -> Any? in
//            print("photo upload error = \(task.error)")
//            print("photo upload result = \(task.result)")
//            observer.send(value: task.error == nil)
//            
//            return nil
//        })
        
        return signal
    }
    
    func delete(photos: [MenuItem.Photo], for item: MenuItem) -> Signal<Bool, NoError> {
        let (signal, observer) = Signal<Bool, NoError>.pipe()
        
        delete(photo: photos[0], for: item).observe {
            if !$0.value! {
                observer.send(value: false)
            } else {
                var photos = photos
                photos.removeFirst()
                
                if photos.count > 0 {
                    self.delete(photos: photos, for: item).observe {
                        if !$0.value! {
                            observer.send(value: false)
                        } else {
                            observer.send(value: true)
                        }
                    }
                } else {
                    observer.send(value: true)
                }
            }
        }

        
        return signal
    }
    
    func delete(photo: MenuItem.Photo, for item: MenuItem) -> Signal<Bool, NoError> {
        let (signal, observer) = Signal<Bool, NoError>.pipe()
        
        let path = "merchants/\((item.category.merchant.id)!)/\(photo.name).jpg"
//        let path = "merchants/\((item.category.merchant.id)!)/\((item.category.id)!)/\(photo.name).jpg"
        let request = AWSS3DeleteObjectRequest()
        request?.bucket = AWS.storageBucket
        request?.key = path
        AWS.storage.deleteObject(request!)
            .continue( { (task: AWSTask<AWSS3DeleteObjectOutput>) -> Any? in
            observer.send(value: task.error == nil)
        })
        
        return signal
    }
    
    #endif
}
