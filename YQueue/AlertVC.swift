//
//  AlertVC.swift
//  YQueue
//
//  Created by Toshio on 05/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class AlertVC: UIViewController {

    @IBOutlet private weak var iconImageView: UIImageView! {
        didSet {
            self.reactive.values(forKeyPath: "alertIcon")
                .take(during: reactive.lifetime)
                .map { $0 as! UIImage? }
                .start(on: QueueScheduler.main)
                .startWithValues { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    
                    self.iconImageView.image = $0
                }
        }
    }
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            self.reactive.values(forKeyPath: "alertTitle")
                .take(during: reactive.lifetime)
                .map { $0 as! String? }
                .start(on: QueueScheduler.main)
                .startWithValues { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    
                    self.titleLabel.text = $0
                }
        }
    }
    @IBOutlet private weak var textLabel: UILabel! {
        didSet {
            self.reactive.values(forKeyPath: "alertText")
                .take(during: reactive.lifetime)
                .map { $0 as! String? }
                .start(on: QueueScheduler.main)
                .startWithValues { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    
                    self.textLabel.text = $0
                }
        }
    }
    
    @IBOutlet private weak var wrapper: UIView! {
        didSet {
            wrapper.layer.cornerRadius = 15
        }
    }

    @IBOutlet private weak var cancelButton: UIButton! {
        didSet {
            cancelButtonSignal = cancelButton.reactive.trigger(for: .touchUpInside)
                .take(during: reactive.lifetime)
            cancelButtonSignal.observe { [weak self] _ in
                guard let `self` = self else {
                    return
                }
                
                self.dismiss(animated: true, completion: nil)
            }
            
            reactive.values(forKeyPath: "cancelButtonTitle")
                .take(during: reactive.lifetime)
                .map { $0 as! String? }
                .start(on: QueueScheduler.main)
                .startWithValues { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    
                    self.cancelButton.setTitle($0, for: .normal)
                }
        }
    }
    
    @IBOutlet private weak var okButton: UIButton! {
        didSet {
            okButtonSignal = okButton.reactive.trigger(for: .touchUpInside)
                .take(during: reactive.lifetime)
            okButtonSignal.observe { [weak self] _ in
                guard let `self` = self else {
                    return
                }
                
                self.dismiss(animated: true, completion: nil)
            }
            
            reactive.values(forKeyPath: "okButtonTitle")
                .take(during: reactive.lifetime)
                .map { $0 as! String? }
                .start(on: QueueScheduler.main)
                .startWithValues { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    
                    self.okButton.setTitle($0, for: .normal)
                }
        }
    }
    
    var alertIcon: UIImage? = nil
    var alertTitle: String? = ""
    var alertText: String? = ""
    var cancelButtonTitle: String? = "Cancel"
    var okButtonTitle: String? = "OK"
    
    var cancelButtonSignal: Signal<Void, NoError>!
    var okButtonSignal: Signal<Void, NoError>!
    
    var background: UIView!
    var showBackground = true
    
    func show(in vc: UIViewController, animated: Bool) {
        vc.view.endEditing(true)
        
        background = UIView(frame: (vc.navigationController?.view.frame)!)
        background.backgroundColor = UIColor.clear
        
        vc.navigationController?.view.addSubview(background)
        vc.present(self, animated: animated, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear // using semi-transparent background color in Storyboard to see interface more real
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if showBackground {
            UIView.animate(withDuration: 0.15, animations: { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                self.background.backgroundColor = UIColor(white: 54.0/255.0, alpha: 0.69)
            })
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        background.backgroundColor = UIColor.clear
        background.removeFromSuperview()
        super.dismiss(animated: flag, completion: completion)
    }
}

extension AlertVC {
    
    // Confirm order
    static func show(in vc: UIViewController, icon: UIImage?, title: String?, text: String?, cancelButtonTitle: String?, okButtonTitle: String?) -> AlertVC {
        let alert = Storyboard.alert()
        alert.modalPresentationStyle = .overCurrentContext
        print("alert = \(alert)")
        alert.alertIcon = icon
        alert.alertTitle = title
        alert.alertText = text
        alert.cancelButtonTitle = cancelButtonTitle
        alert.okButtonTitle = okButtonTitle
        
        alert.show(in: vc, animated: true)
        
        return alert
    }
}
