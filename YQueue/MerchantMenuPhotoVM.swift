//
//  MerchantMenuPhotoVM.swift
//  YQueue
//
//  Created by Aleksandr on 13/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantMenuPhotoVM: NSObject, ModelCollectionViewCellModelProtocol {
    
    var imageLoadingSignal: Signal<Void, NoError>
    private var imageLoadingObserver: Observer<Void, NoError>
    var image = MutableProperty<UIImage?>(nil)
    
    var photo: MenuItem.Photo
    var tapSignal: Signal<Void, NoError>?
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String?
    var collectionView: ModelCollectionView!
    
    init(photo: MenuItem.Photo) {
        self.photo = photo
        
        image <~ photo.image.signal
        (imageLoadingSignal, imageLoadingObserver) = Signal<Void, NoError>.pipe()
        
        let (tapSignal, tapObserver) = Signal<Void, NoError>.pipe()
        self.tapSignal = tapSignal
        self.tapObserver = tapObserver
        
        super.init()
        
        tapSignal.observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            if self.image.value == nil {
                self.refreshPhoto()
            }
        }
    }
    
    func modelBound() {
        refreshPhoto()
    }
    
    private func refreshPhoto() {
        imageLoadingObserver.send(value: ())
        photo.load()
    }
}
