//
//  ModelCollectionView.swift
//  YQueue
//
//  Created by Aleksandr on 10/12/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

protocol ModelCollectionViewCellModelProtocol {
    var tapObserver: Observer<Void, NoError>? { get set }
    var reuseIdentifier: String? { get set }
    var collectionView: ModelCollectionView! { get set }
    
    func modelBound()
}

protocol ModelCollectionViewCellProtocol {
    var modelChangeSignal: Signal<Void, NoError>? { get set }
    var modelChangeObserver: Observer<Void, NoError>? { get set }
    var model: ModelCollectionViewCellModelProtocol? { get set }
}

class ModelCollectionView: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate {
    
    private func reloadDataAndSetDelegates() {
        allowsSelection = false
        delegate = self
        dataSource = self
        reloadData()
    }
    
    var models = [ModelCollectionViewCellModelProtocol]() {
        didSet {
            for var model in models {
                model.collectionView = self
            }
            reloadDataAndSetDelegates()
        }
    }
    
    func removeModel(_ model: ModelCollectionViewCellModelProtocol) {
        models = models.filter { ($0 as! NSObject) != (model as! NSObject) }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return models.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let model = models[indexPath.row]
        
        var reuseIdentifier = "Item"
        if let id: String = model.reuseIdentifier {
            reuseIdentifier = id
        }
        
        var cell: ModelCollectionViewCellProtocol
            = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                            for: indexPath) as! ModelCollectionViewCellProtocol
        
        if cell.modelChangeSignal == nil && cell.modelChangeObserver == nil {
            let (modelChangeSignal, modelChangeObserver) = Signal<Void, NoError>.pipe()
            cell.modelChangeSignal = modelChangeSignal
            cell.modelChangeObserver = modelChangeObserver
        } else {
            cell.modelChangeObserver?.send(value: ())
        }
        
        cell.model = model
        model.modelBound()
        print("created cell \(cell) for index \(indexPath)")
        return cell as! UICollectionViewCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("collection view item selected at path \(indexPath)")
        collectionView.deselectItem(at: indexPath, animated: true)
        if let tapObserver: Observer<Void, NoError> = models[indexPath.row].tapObserver {
            tapObserver.send(value: ())
        }
    }
    
    @IBInspectable var ignorePaddings: Bool = true
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForItem(at: indexPath)
        if let attributes: UICollectionViewLayoutAttributes = attributes,
            ignorePaddings {
            attributes.frame.origin.x = CGFloat(indexPath.row) * attributes.frame.size.width
        }
        
        return attributes
    }
}
