//
//  MerchantEditMenuPhotosTVC.swift
//  YQueue
//
//  Created by Toshio on 10/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantEditMenuPhotosTVC: UITableViewCell, ModelTableViewCellProtocol {
    
    @IBOutlet weak var collectionView: ModelCollectionView!
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: MerchantEditMenuPhotosVM = model as! MerchantEditMenuPhotosVM? {
                model.photos.signal
                    .take(until: modelChangeSignal!)
                    .observeValues { [weak self] in
                        guard let `self` = self else {
                            return
                        }
                        
                        var models = [MerchantEditMenuPhotoVM]()
                        
                        let addModel = MerchantEditMenuPhotoVM(photo: nil)
                        addModel.addSignal.observeValues {
                            model.addPhoto($0)
                        }
                        models.append(addModel)
                        
                        for photo in $0 {
                            let photoModel = MerchantEditMenuPhotoVM(photo: photo)
                            photoModel.deleteSignal.observeValues { _ in
                                model.photos.consume(model.photos.value.filter { $0 != photo })
                            }
                            
                            models.append(photoModel)
                        }
                        
                        self.collectionView.models = models
                }
            }
        }
    }
}
