//
//  MerchantEditMenuPhotoCVC.swift
//  YQueue
//
//  Created by Aleksandr on 10/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantEditMenuPhotoCVC: UICollectionViewCell, ModelCollectionViewCellProtocol {
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            imageView.layer.borderColor = UIColor(white: 245.0/255.0, alpha: 1).cgColor
            imageView.layer.borderWidth = 1
        }
    }
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var errorView: UIView!
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelCollectionViewCellModelProtocol? {
        didSet {
            if let model: MerchantEditMenuPhotoVM = model as! MerchantEditMenuPhotoVM? {
                button.reactive.trigger(for: .touchUpInside)
                    .take(until: modelChangeSignal!)
                    .observeValues {
                        model.tapObserver?.send(value: ())
                }
                
                if let imageLoadingSignal: Signal<Void, NoError> = model.imageLoadingSignal,
                    model.photo != nil {
                    imageView.image = nil // remove "add photo" icon
                    
                    imageLoadingSignal
                        .take(until: modelChangeSignal!)
                        .observeValues { [weak self] in
                            guard let `self` = self else {
                                return
                            }
                            
                            self.loadingIndicator.startAnimating()
                            self.loadingIndicator.isHidden = false
                            self.errorView.isHidden = true
                            
                            model.image.signal
                                .take(until: self.modelChangeSignal!)
                                .take(first: 1)
                                .observeValues { [weak self] in
                                    guard let `self` = self else {
                                        return
                                    }
                                    
                                    self.imageView.image = $0
                                    
                                    self.loadingIndicator.stopAnimating()
                                    self.loadingIndicator.isHidden = true
                                    if $0 == nil {
                                        self.errorView.isHidden = false
                                    }
                                }
                        }
                } else {
                    imageView.image = UIImage(named: "add_photo")
                    loadingIndicator.isHidden = true
                }
            }
        }
    }

}
