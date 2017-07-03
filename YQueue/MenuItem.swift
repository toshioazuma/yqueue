//
//  MenuItem.swift
//  YQueue
//
//  Created by Aleksandr on 23/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result
import AWSDynamoDB

class MenuItem: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    static func dynamoDBTableName() -> String {
        return "MerchantItems"
    }
    
    static func hashKeyAttribute() -> String {
        return "categoryId"
    }
    
    static func rangeKeyAttribute() -> String {
        return "id"
    }
    
    static func ignoreAttributes() -> [String] {
        return ["category", "options", "photos", "isBestSelling", "isChefsSpecial", "isGlutenFree", "isVegeterian"]
    }
    
    var merchantId: String!
    var categoryId: String!
    var id: String = ""
    var name: String = ""
    var number: String = "" {
        didSet {
            numberForSearch = number.lowercased()
        }
    }
    var numberForSearch: String = ""
    var descriptionText: String = "" {
        didSet {
            if descriptionText == "" {
                descriptionText = AWS.emptyString
            }
        }
    }
    var price: Double = 0.0
    var specialOfferText: String = "" {
        didSet {
            if specialOfferText == "" {
                specialOfferText = AWS.emptyString
            }
        }
    }
    var optionsJSONArrayString: String = "[]" {
        didSet {
            options.removeAll()
            let optionsJSONArray: Array<Dictionary<String, Any>>
                = try! JSONSerialization.jsonObject(with: optionsJSONArrayString.data(using: .utf8)!,
                                                    options: JSONSerialization.ReadingOptions())
                    as! Array<Dictionary<String, Any>>
            for optionJSONObject in optionsJSONArray {
                var id = UUID().uuidString.lowercased()
                if let aId: String = optionJSONObject["id"] as! String?  {
                    id = aId
                }
                let option = Option(id: id,//optionJSONObject["id"] as! String!,
                                    name: optionJSONObject["name"] as! String!,
                                    price: optionJSONObject["price"] as! Double!)
                options.append(option)
            }
            
            options.sort { $0.0.price < $0.1.price }
        }
    }
    var photosJSONArrayString: String = "[]" {
        didSet {
            photos.removeAll()
            let photosJSONArray: Array<Dictionary<String, Any>>
                = try! JSONSerialization.jsonObject(with: photosJSONArrayString.data(using: .utf8)!,
                                                    options: JSONSerialization.ReadingOptions())
                as! Array<Dictionary<String, Any>>
            for photoJSONObject in photosJSONArray {
                let photo = Photo(item: self,
                                  name: photoJSONObject["photo"] as! String!)
                photos.append(photo)
            }
        }
    }
    var bestSelling: Int = 0
    var chefsSpecial: Int = 0
    var glutenFree: Int = 0
    var vegeterian: Int = 0
    
    var isBestSelling: Bool {
        get {
            return bestSelling == 1
        } set {
            bestSelling = newValue ? 1 : 0
        }
    }
    
    var isChefsSpecial: Bool {
        get {
            return chefsSpecial == 1
        } set {
            chefsSpecial = newValue ? 1 : 0
        }
    }
    
    var isGlutenFree: Bool {
        get {
            return glutenFree == 1
        } set {
            glutenFree = newValue ? 1 : 0
        }
    }
    
    var isVegeterian: Bool {
        get {
            return vegeterian == 1
        } set {
            vegeterian = newValue ? 1 : 0
        }
    }
    
    var category: MenuCategory!
    var options = Array<Option>()
    var photos = Array<Photo>()
    
    func prepareForSave() {
        if id == "" {
            id = UUID().uuidString.lowercased()
        }
        
        merchantId = category.merchantId
        categoryId = category.id
        
        var optionsJSONArrayString = "[]"
        if options.count > 0 {
            var optionsJSONArray = Array<Dictionary<String, Any>>()
            for option in self.options {
                var optionJSONObject = Dictionary<String, Any>()
                optionJSONObject["id"] = option.id
                optionJSONObject["name"] = option.name
                optionJSONObject["price"] = option.price
                
                optionsJSONArray.append(optionJSONObject)
            }
            
            
            optionsJSONArrayString = String(data: try! JSONSerialization.data(withJSONObject: optionsJSONArray,
                                                                     options: JSONSerialization.WritingOptions()),
                                            encoding: .utf8)!
        }
        self.optionsJSONArrayString = optionsJSONArrayString
        
        var photosJSONArrayString = "[]"
        if photos.count > 0 {
            var photosJSONArray = Array<Dictionary<String, Any>>()
            for photo in self.photos {
                var photoJSONObject = Dictionary<String, Any>()
                photoJSONObject["photo"] = photo.name
                
                photosJSONArray.append(photoJSONObject)
            }
            
            
            photosJSONArrayString = String(data: try! JSONSerialization.data(withJSONObject: photosJSONArray,
                                                                            options: JSONSerialization.WritingOptions()),
                                            encoding: .utf8)!
        }
        self.photosJSONArrayString = photosJSONArrayString
    }
    
    class Option: NSObject {
        var id: String
        var name: String
        var price: Double
        
        init(id: String, name: String, price: Double) {
            self.id = id
            self.name = name
            self.price = price
        }
        
        static func ==(lhs: Option, rhs: Option) -> Bool {
            return lhs.name == rhs.name && lhs.price == rhs.price
        }
    }
    
    public class Photo: NSObject {
        var item: MenuItem?
        var name: String = ""
        var image = MutableProperty<UIImage?>(nil)
        
        func load() {
            load(try: 0)
        }
        
        private func load(try tryNumber: Int) {
            if image.value != nil {
                image.consumeCurrent()
                return
            }
            
            if let item: MenuItem = item {
                Api.menuItems.download(self, for: item)
                    .observe(on: QueueScheduler.main)
                    .observe { [weak self] in
                        guard let `self` = self else {
                            return
                        }
                        
                        if let image: UIImage = $0.value! {
                            self.image.consume(image)
                        } else {
                            let limit = 5
                            if limit > tryNumber {
                                self.load(try: tryNumber+1)
                            } else {
                                self.image.consume(nil)
                            }
                        }
                }
            }
        }
        
        init(item: MenuItem, name: String) {
            self.item = item
            self.name = name
        }
        
        init(item: MenuItem?, image: UIImage) {
            self.item = item
            self.image.consume(image)
        }
    }
}
