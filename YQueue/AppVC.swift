//
//  AppVC.swift
//  YQueue
//
//  Created by Toshio on 04/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import SideMenu

class AppVC: BaseVC {

    private static var leftMenuNC: UISideMenuNavigationController? = nil
    private var overlay = UIView()
    
    @objc private func openMenu() {
        navigationController?.view.addSubview(overlay)
        UIView.animate(withDuration: SideMenuManager.menuAnimationPresentDuration) {
            self.overlay.backgroundColor = UIColor.black.withAlphaComponent(0.59)
        }
        present(AppVC.leftMenuNC!, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppVC.leftMenuNC = nil
        setupNavigationBar()
        setupLeftMenu()
        
        #if CUSTOMER
            if Api.push.openedWithNotification {
                Api.push.openedWithNotification = false
                Storyboard.openOrderHistory()
            }
        #endif
    }
    
    open func reload() {
        
    }
    
    private func setupNavigationBar() {
        if let nav = navigationController {
            navigationItem.hidesBackButton = true
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "menu_button"),
                                                                                     style: .plain,
                                                                                     target: self, action: #selector(openMenu))
            
            
            nav.navigationBar.barTintColor = UIColor.white
            nav.navigationBar.tintColor = UIColor(white: 141.0/255.0, alpha: 1.0)
            nav.navigationBar.setBottomBorderColor(color: UIColor(white: 241.0/255.0, alpha: 1.0), height: 0.5)
            
            if #available(iOS 8.2, *) {
                nav.navigationBar.titleTextAttributes = [
                    NSFontAttributeName : UIFont.systemFont(ofSize: 15, weight: UIFontWeightThin)
                ]
            } else {
                nav.navigationBar.titleTextAttributes = [
                    NSFontAttributeName : UIFont.systemFont(ofSize: 15)
                ]
            }
        }
    }
    
    private func setupLeftMenu() {
        if AppVC.leftMenuNC == nil {
            AppVC.leftMenuNC = Storyboard.leftMenu() as? UISideMenuNavigationController
            
            AppVC.leftMenuNC?.leftSide = true
            SideMenuManager.menuLeftNavigationController = AppVC.leftMenuNC
            SideMenuManager.menuPresentMode = .menuSlideIn
            SideMenuManager.menuWidth = 205
            SideMenuManager.menuFadeStatusBar = false
            SideMenuManager.menuShadowRadius = 0
        }
        
        overlay.frame = self.view.bounds
        
        NotificationCenter.default.reactive.notifications(forName: Notification.Name(rawValue: "SideMenuTap"))
            .take(during: reactive.lifetime)
            .observe { [weak self] _ in
                guard let `self` = self else {
                    return
                }
                
                UIView.animate(withDuration: SideMenuManager.menuAnimationDismissDuration, animations: {
                    self.overlay.backgroundColor = UIColor.clear
                    }, completion: { _ in
                        self.overlay.removeFromSuperview()
                })
            }
    }
}
