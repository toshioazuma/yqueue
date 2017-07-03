//
//  BaseVC.swift
//  YQueue
//
//  Created by Aleksandr on 03/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class BaseVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private var refreshControl: UIRefreshControl?
    private var refreshControlSignal: Signal<Void, NoError>?
    private var refreshControlObserver: Observer<Void, NoError>?
//    func backButtonClicked() {
//        _ = navigationController?.popViewController(animated: true)
//        
//        if let backButtonObserver: Observer<Void, NoError> = backButtonObserver {
//            backButtonObserver.send(value: ())
//        }
//    }
    
    func addRefreshControl(to tableView: UITableView) -> Signal<Void, NoError> {
        let (refreshControlSignal, refreshControlObserver) = Signal<Void, NoError>.pipe()
        self.refreshControlSignal = refreshControlSignal
        self.refreshControlObserver = refreshControlObserver
        
        refreshControl = UIRefreshControl()
        _ = refreshControl?.reactive.trigger(for: .valueChanged)
            .take(during: reactive.lifetime)
            .observeValues { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                self.refreshControl?.endRefreshing()
                self.refreshControlObserver?.send(value: ())
            }
        
        tableView.addSubview(refreshControl!)
        
        return refreshControlSignal
    }
    
    private var backButtonSignal: Signal<Void, NoError>?
    private var backButtonObserver: Observer<Void, NoError>?
    func backButtonClicked() {
        _ = navigationController?.popViewController(animated: true)
        
        if let backButtonObserver: Observer<Void, NoError> = backButtonObserver {
            backButtonObserver.send(value: ())
        }
    }
    
    private var rightButtonSignal: Signal<Void, NoError>?
    private var rightButtonObserver: Observer<Void, NoError>?
    func rightButtonClicked() {
        if let rightButtonObserver: Observer<Void, NoError> = rightButtonObserver {
            rightButtonObserver.send(value: ())
        }
    }
    
    func addRightButton(_ button: UIBarButtonItem) {
        navigationItem.rightBarButtonItem = button
    }
    
    func addRightButton(image: UIImage, addSpace: Bool) -> Signal<Void, NoError> {
        let (rightButtonSignal, rightButtonObserver) = Signal<Void, NoError>.pipe()
        self.rightButtonSignal = rightButtonSignal
        self.rightButtonObserver = rightButtonObserver
        
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(rightButtonClicked))
        
        if addSpace {
            navigationItem.rightBarButtonItem = button
        } else {
            let negativeSpacer = UIBarButtonItem.init(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            negativeSpacer.width = -8
            navigationItem.rightBarButtonItems = [negativeSpacer, button]
        }
        
        return self.rightButtonSignal!
    }
    
    func addRightButton(image: UIImage) -> Signal<Void, NoError> {
        return addRightButton(image: image, addSpace: false)
    }
    
    func addRightButton(type: UIBarButtonSystemItem) -> Signal<Void, NoError> {
        let (rightButtonSignal, rightButtonObserver) = Signal<Void, NoError>.pipe()
        self.rightButtonSignal = rightButtonSignal
        self.rightButtonObserver = rightButtonObserver
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: type, target: self, action: #selector(rightButtonClicked))
        return self.rightButtonSignal!
    }
    
    func addBackButton() -> Signal<Void, NoError> {
        let (backButtonSignal, backButtonObserver) = Signal<Void, NoError>.pipe()
        self.backButtonSignal = backButtonSignal
        self.backButtonObserver = backButtonObserver
        
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_button"),
                                                           style: .plain,
                                                           target: self, action: #selector(backButtonClicked))
        
        return self.backButtonSignal!
    }
    
    func noBackButton() {
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = nil
    }
    
    func hideNavigationBar() {
        navigationController?.isNavigationBarHidden = true
        /*reactive.trigger(for: #selector(viewWillAppear(_:))).observe { _ in
            self.navigationController?.isNavigationBarHidden = true
        }
        reactive.trigger(for: #selector(viewWillDisappear(_:))).observe { _ in
            self.navigationController?.isNavigationBarHidden = false
        }
        let gr = UITapGestureRecognizer()
        gr.numberOfTapsRequired = 1*/
    }
    
    func addTapGestureRecognizer() {
        // TEMPORARY: RAC5 still has no UIGestureRecognizer supported
        let gr = UITapGestureRecognizer()
        gr.numberOfTapsRequired = 1
        gr.addTarget(self, action: #selector(tappedGestureRecognizer))
        
        view.addGestureRecognizer(gr)
    }
    
    @objc private func tappedGestureRecognizer() {
        view.endEditing(true)
    }
    
    lazy var keyboardSignal: Signal<CGFloat, NoError> = { [unowned self] in
        let nc = NotificationCenter.default
        return Signal
            .merge([
                nc.reactive.notifications(forName: Notification.Name.UIKeyboardWillShow),
                nc.reactive.notifications(forName: Notification.Name.UIKeyboardWillHide)])
            .take(during: self.reactive.lifetime)
            .map { $0 as Notification }
            .map {
                print("keyboard info = \($0.userInfo)")
                let frame = ($0.userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
                if frame.origin.y >= self.view.frame.size.height {
                    return 0
                } else {
                    return self.view.frame.size.height - frame.origin.y//frame.size.height
                }
            }
        }()
}
