//
//  MerchantMenuListTVC.swift
//  YQueue
//
//  Created by Aleksandr on 24/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class MerchantMenuListTVC: UITableViewCell, ModelTableViewCellProtocol {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var descriptionTextLabel: UILabel!
    @IBOutlet weak var descriptionHeight: NSLayoutConstraint!
    @IBOutlet weak var separatorBetweenDescriptionAndOption: UIView!
    @IBOutlet weak var optionLabel: UILabel!
    @IBOutlet weak var optionArrow: UIImageView!
    @IBOutlet weak var optionButton: UIButton!
    @IBOutlet var optionHeight: NSLayoutConstraint!
    @IBOutlet weak var tagWrapperHeight: NSLayoutConstraint!
    @IBOutlet weak var tagImageView1: UIImageView!
    @IBOutlet weak var tagImageView2: UIImageView!
    @IBOutlet weak var tagImageView3: UIImageView!
    @IBOutlet weak var tagImageView4: UIImageView!
    @IBOutlet weak var photosCollectionView: ModelCollectionView!
    @IBOutlet weak var photosHeight: NSLayoutConstraint!
    @IBOutlet weak var photosSeparator: UIView!
    @IBOutlet weak var editButton: UIButton! {
        didSet {
            editButton.layer.cornerRadius = 15.0
        }
    }
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: MerchantMenuListVM = model as! MerchantMenuListVM? {
                editButton.reactive.trigger(for: .touchUpInside)
                    .take(until: modelChangeSignal!)
                    .observeValues {
                        model.tapObserver?.send(value: ())
                }
                
                nameLabel.reactive.text <~ model.name
                    .signal.take(until: modelChangeSignal!)
            
                model.descriptionText
                    .signal.take(until: modelChangeSignal!)
                    .observeValues { [weak self] in
                        guard let `self` = self else {
                            return
                        }
                        
                        self.descriptionTextLabel.text = $0
                        self.descriptionTextLabel.layoutIfNeeded()
                    }
        
                priceLabel.reactive.text <~ model.price.map { String(format: "$ %.2f", $0) }
                    .signal.take(until: modelChangeSignal!)
                
                optionLabel.reactive.text <~ model.option.signal.take(until: modelChangeSignal!).map {
                    $0 == nil ? "" : $0?.name
                }

                model.descriptionText.signal.combineLatest(with: model.options.signal)
                    .take(until: modelChangeSignal!)
                    .observeValues { [weak self] in
                        guard let `self` = self else {
                            return
                        }
                        
                        self.separatorBetweenDescriptionAndOption
                            .isHidden = $0.aws == "" || $1.count == 0
                        
                        self.descriptionHeight.constant = $0.aws == "" ? 0 : 15
                        self.descriptionTextLabel.text = $0.aws
                        print("descriptionHeight = \(self.descriptionHeight)")
                        
//                        self.optionHeight.constant = $1.count == 0 ? 0 : 30
                        print("optionHeight = \(self.optionHeight)")
                        print("options = \($1)")
                        self.optionHeight.isActive = $1.count == 0
                        self.optionLabel.text = $1.count > 0 ? $1[0].name : "None"
                }
                
                optionButton.reactive.trigger(for: .touchUpInside)
                    .take(until: modelChangeSignal!)
                    .observeValues { [weak self] in
                        guard let `self` = self else {
                            return
                        }
                        
                        _ = MerchantMenuOptionAlertVC.show(in: Storyboard.appVC!,
                                                           withOptions: model.menuItem.options,
                                                           optionLabel: self.optionLabel,
                                                           selectionCallback: {
                                                            model.option.consume($0)
                                                            model.tableView.reloadData()
                                                            model.offset.consume(-model.offset.value)
                        }, offsetCallback: {
                            model.offset.consume($0)
                        })
                }
                
                model.tagImages.signal.take(until: modelChangeSignal!).observeValues { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    
                    self.tagWrapperHeight.constant = $0.count == 0 ? 0 : $0.count > 2 ? 80 : 40
                    for (i, imageView) in [self.tagImageView1,
                                           self.tagImageView2,
                                           self.tagImageView3,
                                           self.tagImageView4].enumerated() {
                        if $0.count > i {
                            imageView?.image = $0[i]
                        } else {
                            imageView?.image = nil
                        }
                    }
                }
                
                model.photos.signal
                    .take(until: modelChangeSignal!)
                    .observeValues { [weak self] in
                        guard let `self` = self else {
                            return
                        }
                        
                        print("photos = \($0)")
                        let itemSize: CGFloat = 70.0
                        let linesCount = ceil(itemSize * CGFloat($0.count) / Storyboard.screenFrame.size.width)
                        print("photosCollectionViewWidth = \(Storyboard.screenFrame.size.width)")
                        print("linesCount = \(linesCount)")
                        print("photosHeight = \(itemSize * linesCount)")
                        self.photosHeight.constant = itemSize * linesCount
                        self.photosSeparator.isHidden = $0.count == 0
                        
                        var models = [MerchantMenuPhotoVM]()
                        for photo in $0 {
                            models.append(MerchantMenuPhotoVM(photo: photo))
                        }
                        
                        self.photosCollectionView.models = models
                }
            }
        }
    }
}
