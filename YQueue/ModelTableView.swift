//
//  ModelTableView.swift
//  YQueue
//
//  Created by Toshio on 05/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

protocol ModelTableViewCellModelProtocol {
    var tapObserver: Observer<Void, NoError>? { get set }
    var reuseIdentifier: String? { get set }
    var rowHeight: CGFloat? { get set }
    var estimatedRowHeight: CGFloat? { get set }
    var tableView: ModelTableView! { get set }
    
    func modelBound()
}

protocol ModelTableViewCellProtocol {
    var modelChangeSignal: Signal<Void, NoError>? { get set }
    var modelChangeObserver: Observer<Void, NoError>? { get set }
    var model: ModelTableViewCellModelProtocol? { get set }
}

class ModelTableViewCellModel: NSObject, ModelTableViewCellModelProtocol {
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String?
    var rowHeight: CGFloat?
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    init(reuseIdentifier: String, rowHeight: CGFloat) {
        self.reuseIdentifier = reuseIdentifier
        self.rowHeight = rowHeight
    }
    init(reuseIdentifier: String) {
        self.reuseIdentifier = reuseIdentifier
    }
    init(rowHeight: CGFloat) {
        self.rowHeight = rowHeight
    }
    func modelBound() {
    }
}

class ModelTableViewCell: UITableViewCell, ModelTableViewCellProtocol {
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol?
}

class ModelTableView: UITableView, UITableViewDataSource, UITableViewDelegate {
    
    private func reloadDataAndSetDelegates() {
        delegate = self
        dataSource = self
        reloadData()
    }
    
    var headerModel: ModelTableViewCellModelProtocol? {
        didSet {
            if var headerModel: ModelTableViewCellModelProtocol = headerModel {
                headerModel.tableView = self
            }
            reloadDataAndSetDelegates()
        }
    }
    
    var models = [ModelTableViewCellModelProtocol]() {
        didSet {
            for var model in models {
                model.tableView = self
            }
            reloadDataAndSetDelegates()
        }
    }
    
    func remove(model: ModelTableViewCellModelProtocol) {
        models = models.filter { ($0 as! NSObject) != (model as! NSObject) }
    }
    
    func reload(cell: UITableViewCell) {
        let indexPath = self.indexPath(for: cell)
        if let indexPath: IndexPath = indexPath {
            OperationQueue.main.addOperation {
                self.reloadRows(at: [indexPath], with: .automatic)
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("model table view has \(models.count) models")
        return models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models[indexPath.row]
        
        var reuseIdentifier = "Item"
        if let id: String = model.reuseIdentifier {
            reuseIdentifier = id
        }
        print("model \(model) has reuse id \(reuseIdentifier)")
        
        var cell: ModelTableViewCellProtocol
            = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier,
                                            for: indexPath) as! ModelTableViewCellProtocol
        
        if cell.modelChangeSignal == nil && cell.modelChangeObserver == nil {
            let (modelChangeSignal, modelChangeObserver) = Signal<Void, NoError>.pipe()
            cell.modelChangeSignal = modelChangeSignal
            cell.modelChangeObserver = modelChangeObserver
        } else {
            cell.modelChangeObserver?.send(value: ())
        }
        
        cell.model = model
        model.modelBound()
        
        return cell as! UITableViewCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let tapObserver: Observer<Void, NoError> = models[indexPath.row].tapObserver {
            tapObserver.send(value: ())
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let model = models[indexPath.row]
        if let height: CGFloat = model.rowHeight {
            print("tableView rowHeight custom = \(height)")
            return height
        } else if let _: CGFloat = model.estimatedRowHeight {
            print("tableView rowHeight dynamic")
            return UITableViewAutomaticDimension
        } else {
            print("tableView rowHeight default = \(tableView.rowHeight)")
            return tableView.rowHeight
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let model = models[indexPath.row]
        if let estimatedHeight: CGFloat = model.estimatedRowHeight {
            print("tableView rowEstimatedHeight custom = \(estimatedHeight)")
            return estimatedHeight
        } else if let height: CGFloat = model.rowHeight {
            print("tableView rowEstimatedHeight static = \(height)")
            return height
        } else {
            print("tableView rowHeight default = \(tableView.estimatedRowHeight)")
            return 0.0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let headerModel: ModelTableViewCellModelProtocol = headerModel,
            let reuseIdentifier: String = headerModel.reuseIdentifier {
            return tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let headerModel: ModelTableViewCellModelProtocol = headerModel,
            let height: CGFloat = headerModel.rowHeight {
            return height
        }
        
        return tableView.sectionHeaderHeight
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}
