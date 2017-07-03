//
//  MerchantEditMenuPhotoVM.swift
//  YQueue
//
//  Created by Aleksandr on 10/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantEditMenuPhotoVM: NSObject, ModelCollectionViewCellModelProtocol, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var imageLoadingSignal: Signal<Void, NoError>?
    private var imageLoadingObserver: Observer<Void, NoError>?
    var image = MutableProperty<UIImage?>(nil)
    
    var photo: MenuItem.Photo?
    var addSignal: Signal<UIImage, NoError>
    private var addObserver: Observer<UIImage, NoError>
    var deleteSignal: Signal<Void, NoError>
    private var deleteObserver: Observer<Void, NoError>
    var tapSignal: Signal<Void, NoError>?
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String?
    var collectionView: ModelCollectionView!
    
    init(photo: MenuItem.Photo?) {
        self.photo = photo
        
        if let photo: MenuItem.Photo = photo {
            image <~ photo.image.signal
            
            let (imageLoadingSignal, imageLoadingObserver) = Signal<Void, NoError>.pipe()
            self.imageLoadingSignal = imageLoadingSignal
            self.imageLoadingObserver = imageLoadingObserver
        }
        
        let (tapSignal, tapObserver) = Signal<Void, NoError>.pipe()
        self.tapSignal = tapSignal
        self.tapObserver = tapObserver
        
        (addSignal, addObserver) = Signal<UIImage, NoError>.pipe()
        (deleteSignal, deleteObserver) = Signal<Void, NoError>.pipe()
        
        super.init()
        
        tapSignal.observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            if photo != nil {
                if self.image.value == nil {
                    self.refreshPhoto()
                } else {
                    self.promptDelete()
                }
            } else {
                self.addPhoto()
            }
        }
    }
    
    private func promptDelete() {
        let alert = UIAlertController(title: nil,
                                      message: "Choose action",
                                      preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete photo",
                                      style: .destructive,
                                      handler: { [weak self] _ in
                                        guard let `self` = self else {
                                            return
                                        }
                                        self.deleteObserver.send(value: ())
        }))
        alert.addAction(UIAlertAction(title: "Cancel",
                                      style: .cancel,
                                      handler: nil))
        
        Storyboard.present(alert)
    }
    
    private func addPhoto() {
        pickPhoto(from: .photoLibrary)
//        let alert = UIAlertController(title: nil,
//                                      message: "Choose photo source",
//                                      preferredStyle: .actionSheet)
//        alert.addAction(UIAlertAction(title: "Camera",
//                                      style: .default,
//                                      handler: { _ in
//            self.pickPhoto(from: .camera)
//        }))
//        alert.addAction(UIAlertAction(title: "Gallery",
//                                      style: .default,
//                                      handler: { _ in
//            self.pickPhoto(from: .photoLibrary)
//        }))
//        alert.addAction(UIAlertAction(title: "Cancel",
//                                      style: .cancel,
//                                      handler: nil))
//        
//        Storyboard.present(alert)
    }
    
    private func pickPhoto(from source: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.delegate = self
        Storyboard.present(picker)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let maxSize: CGFloat = 1920.0
            if image.size.width > maxSize || image.size.height > maxSize {
                var newSize = CGSize()
                if image.size.width > image.size.height {
                    newSize.width = maxSize
                    newSize.height = maxSize/image.size.width * image.size.height
                } else {
                    newSize.width = maxSize/image.size.height * image.size.width
                    newSize.height = maxSize
                }
                addObserver.send(value: image.resized(to: newSize))
            } else {
                addObserver.send(value: image)
            }
        } else{
            print("Something went wrong")
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func modelBound() {
        if photo != nil {
            refreshPhoto()
        }
    }
    
    private func refreshPhoto() {
        if let photo: MenuItem.Photo = photo,
            let imageLoadingObserver: Observer<Void, NoError> = imageLoadingObserver {
            imageLoadingObserver.send(value: ())
            photo.load()
        }
    }
}
