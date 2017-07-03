//
//  Storyboard.swift
//  YQueue
//
//  Created by Aleksandr on 03/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import MBProgressHUD

class Storyboard: NSObject {
    
    private static let main = UIStoryboard(name: "Main", bundle: nil)
    #if MERCHANT
    private static var app = UIStoryboard(name: "Merchant", bundle: nil)
    #else
    private static var app = UIStoryboard(name: "Customer", bundle: nil)
    #endif
    
    static func pop(_ viewController: UIViewController) {
        if let nav = viewController.navigationController {
            _ = nav.popViewController(animated: true)
        }
    }
    
    static func pop() {
        if let nav = appVC?.navigationController {
            _ = nav.popViewController(animated: true)
        }
    }
    
    
    // MARK:
    // MARK:
    // MARK: Main storyboard
    static var screenFrame: CGRect = {
        if let nav = appVC?.navigationController {
            return nav.view.frame
        }
        
        return CGRect()
    }()
    
    static var screenView: UIView = {
        return (UIApplication.shared.keyWindow?.subviews.last)!
    }()
    
    private static var progressHUD: MBProgressHUD?
    private static var progressHUDRetainCount = 0
    static func showProgressHUD() {
        OperationQueue.main.addOperation {
            if progressHUD == nil {
                progressHUD = MBProgressHUD.showAdded(to: screenView, animated: true)
                progressHUDRetainCount = 1
            } else {
                progressHUDRetainCount += 1
            }
        }
    }
    
    static func hideProgressHUD() {
        OperationQueue.main.addOperation {
            if let progressHUD: MBProgressHUD = progressHUD {
                progressHUDRetainCount -= 1
                if progressHUDRetainCount == 0 {
                    progressHUD.hide(animated: true)
                    progressHUD.removeFromSuperview()
                    Storyboard.progressHUD = nil
                }
            }
        }
    }
    
    static func proceedToApp(from viewController: UIViewController) {
        if let nav = viewController.navigationController {
            _ = nav.popToRootViewController(animated: false)
            nav.isNavigationBarHidden = false
            
            appVC = app.instantiateInitialViewController() as! AppVC?
            nav.pushViewController(appVC!, animated: true)
            
            Api.push.register()
            #if CUSTOMER
                Location.shared.free()
            #endif
        }
    }
    
    static func recoverPassword(from viewController: UIViewController) {
        if let nav = viewController.navigationController {
            nav.pushViewController(main.instantiateViewController(withIdentifier: "ForgotPassword"),
                                   animated: true)
        }
    }
    
    #if CUSTOMER
    static func signUp(from viewController: UIViewController) {
        if let nav = viewController.navigationController {
            nav.pushViewController(main.instantiateViewController(withIdentifier: "Signup"),
    animated: true)
        }
    }
    
    static func confirmRegistration(from viewController: UIViewController, forUserWithEmail email: String) {
        if let nav = viewController.navigationController {
            let confirmVC: ConfirmRegistrationVC
                = main.instantiateViewController(withIdentifier: "ConfirmRegistration") as! ConfirmRegistrationVC
            confirmVC.email = email
            nav.pushViewController(confirmVC, animated: true)
        }
    }
    #endif
    
    // MARK: Alerts
    
    static func alert() -> AlertVC {
        return (main.instantiateViewController(withIdentifier: "Alert") as! AlertVC)
    }
    
    static func present(_ vc: UIViewController) {
        if let nav = appVC?.navigationController {
            nav.present(vc, animated: true, completion: nil)
        }
    }
    
    #if CUSTOMER
    
    static func specialOfferAlert() -> CustomerMenuSpecialOfferAlertVC {
        return (app.instantiateViewController(withIdentifier: "MenuSpecialOfferAlert")
            as! CustomerMenuSpecialOfferAlertVC)
    }
    
    static func menuOptionAlert() -> CustomerMenuOptionAlertVC {
        return (app.instantiateViewController(withIdentifier: "MenuOptionAlert")
            as! CustomerMenuOptionAlertVC)
    }
    
    static func slipOptionAlert() -> CustomerSlipOptionAlertVC {
        return (app.instantiateViewController(withIdentifier: "SlipOptionAlert")
            as! CustomerSlipOptionAlertVC)
    }
    
    static func paymentRewardsCouponsAlert() -> CustomerPaymentRewardsCouponsAlertVC {
        return (app.instantiateViewController(withIdentifier: "PaymentRewardsCouponsAlert")
            as! CustomerPaymentRewardsCouponsAlertVC)
    }
    
    #endif
    
    #if MERCHANT
    
    static func menuCategoryAlert() -> MerchantEditMenuCategoryAlertVC {
        return (app.instantiateViewController(withIdentifier: "MenuCategoryAlert")
                    as! MerchantEditMenuCategoryAlertVC)
    }
    
    static func menuOptionAlert() -> MerchantMenuOptionAlertVC {
        return (app.instantiateViewController(withIdentifier: "MenuOptionAlert")
                    as! MerchantMenuOptionAlertVC)
    }
    
    #endif
    
    
    // MARK:
    // MARK:
    // MARK: Common app
    static var appVC: AppVC?
    
    static func leftMenu() -> UIViewController {
        return main.instantiateViewController(withIdentifier: "LeftMenuNavigation")
    }
    
    private static func openLeftMenuVC(_ vc: UIViewController) {
        if let nav = appVC?.navigationController {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SideMenuTap"),
                                            object: nil)
            nav.dismiss(animated: true, completion: nil)
            
            if (nav.viewControllers.last?.isEqual(vc))! {
                // skip
                print("openLeftMenuVC skip")
            } else {
                print("openLeftMenuVC pop to appVC, navigation stack = \(nav.viewControllers)")
                _ = nav.popToViewController(appVC!, animated: false)
                if !(appVC?.isEqual(vc))! {
                    print("openLeftMenuVC push vc")
                    nav.pushViewController(vc, animated: false)
                }
            }
        }
    }
    
    static func openHome() {
        appVC?.reload()
        openLeftMenuVC(appVC!)
    }
    
    static func logout() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        _ = Api.auth.logout()
        
        if let nav = appVC?.navigationController {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SideMenuTap"),
                                            object: nil)
            nav.dismiss(animated: true, completion: nil)
            nav.isNavigationBarHidden = true
            
            appVC = nil
            _ = nav.popToRootViewController(animated: true)
        }
    }
    
    #if MERCHANT
    // MARK:
    // MARK:
    // MARK: Merchant app
    static func openDashboard() {
        openHome()
    }
    
    // MARK:
    // MARK: Menu
    static func openMenu() {
        if let _ = appVC?.navigationController {
            let settingsVC = app.instantiateViewController(withIdentifier: "Menu")
            openLeftMenuVC(settingsVC)
        }
    }
    
    static func openCategories(editCallback: @escaping ([MenuCategory]) -> Void) {
        if let nav = appVC?.navigationController {
            let categoriesVC: MerchantCategoriesVC = app.instantiateViewController(withIdentifier: "Categories") as! MerchantCategoriesVC
            categoriesVC.editCallback = editCallback
            nav.pushViewController(categoriesVC, animated: true)
        }
    }
    
    static func openAddCategory(saveCallback: @escaping (MenuCategory?) -> Void) {
        openEditMenuCategory(nil, saveCallback: saveCallback)
    }
    
    static func openEditMenuCategory(_ menuCategory: MenuCategory?, saveCallback: @escaping (MenuCategory?) -> Void) {
        if let nav = appVC?.navigationController {
            let editCategoryVC: MerchantCategoryVC = app.instantiateViewController(withIdentifier: "EditCategory")
                as! MerchantCategoryVC
            editCategoryVC.menuCategory = menuCategory
            editCategoryVC.saveCallback = saveCallback
            nav.pushViewController(editCategoryVC, animated: true)
        }
    }
    
    
    static func getMenuList(for menuCategory: MenuCategory) -> MerchantMenuListVC {
        let menuListVC: MerchantMenuListVC = app.instantiateViewController(withIdentifier: "MenuList")
            as! MerchantMenuListVC
        menuListVC.menuCategory = menuCategory
        return menuListVC
    }
    
    static func openAddMenuItem(saveCallback: @escaping (MenuItem) -> Void) {
        openEditMenuItem(nil, saveCallback: saveCallback)
    }
    
    static func openEditMenuItem(_ menuItem: MenuItem?, saveCallback: @escaping (MenuItem) -> Void) {
        if let nav = appVC?.navigationController {
            let editMenuVC: MerchantEditMenuVC = app.instantiateViewController(withIdentifier: "EditMenu")
                as! MerchantEditMenuVC
            editMenuVC.menuItem = menuItem
            editMenuVC.saveCallback = saveCallback
            nav.pushViewController(editMenuVC, animated: true)
        }
    }
    
    // MARK:
    // MARK: Settings
    static func openSettings() {
        if let _ = appVC?.navigationController {
            let settingsVC = app.instantiateViewController(withIdentifier: "Settings")
            openLeftMenuVC(settingsVC)
        }
    }
    
    static func openEditRestaurant() {
        if let nav = appVC?.navigationController {
            let editRestaurantVC = app.instantiateViewController(withIdentifier: "EditRestaurant")
            nav.pushViewController(editRestaurantVC, animated: true)
        }
    }
    
    static func openChangePassword() {
        if let nav = appVC?.navigationController {
            let changePasswordVC = app.instantiateViewController(withIdentifier: "ChangePassword")
            nav.pushViewController(changePasswordVC, animated: true)
        }
    }
    
    static func openCategories() {
        if let nav = appVC?.navigationController {
            let categoriesVC = app.instantiateViewController(withIdentifier: "Categories")
            nav.pushViewController(categoriesVC, animated: true)
        }
    }
    
    // MARK:
    // MARK: Feedback
    static func openFeedback() {
        if let _ = appVC?.navigationController {
            let settingsVC = app.instantiateViewController(withIdentifier: "Feedback")
            openLeftMenuVC(settingsVC)
        }
    }
    
    #endif
    
    #if CUSTOMER
    // MARK:
    // MARK:
    // MARK: Customer app
    
    // MARK:
    // MARK: Search
    public static var dineIn: Bool?
    
    static func openHomeTutorial() {
        let ud = UserDefaults.standard
        if !ud.bool(forKey: "home_tutorial_shown") {
            if let nav = appVC?.navigationController {
                let tutorialVC = app.instantiateViewController(withIdentifier: "HomeTutorial")
                tutorialVC.modalPresentationStyle = .overCurrentContext
                nav.present(tutorialVC, animated: false, completion: nil)
                ud.set(true, forKey: "home_tutorial_shown")
                ud.synchronize()
            }
        }
    }
    
    static func openSearchTutorial() {
        let ud = UserDefaults.standard
        if !ud.bool(forKey: "search_tutorial_shown") {
            if let nav = appVC?.navigationController {
                let tutorialVC = app.instantiateViewController(withIdentifier: "SearchTutorial")
                tutorialVC.modalPresentationStyle = .overCurrentContext
                nav.present(tutorialVC, animated: false, completion: nil)
                ud.set(true, forKey: "search_tutorial_shown")
                ud.synchronize()
            }
        }
    }
    
    static func openSlipTutorial() {
        guard let `dineIn` = dineIn else {
            return
        }
        
        if !dineIn {
            return
        }
        
        let ud = UserDefaults.standard
        if !ud.bool(forKey: "dine_in_slip_tutorial_shown") {
            if let nav = appVC?.navigationController {
                let tutorialVC = app.instantiateViewController(withIdentifier: "SlipTutorial")
                tutorialVC.modalPresentationStyle = .overCurrentContext
                nav.present(tutorialVC, animated: false, completion: nil)
                ud.set(true, forKey: "dine_in_slip_tutorial_shown")
                ud.synchronize()
            }
        }
    }
    
    static func openSearch(newDineIn: Bool) {
        dineIn = newDineIn
        openSearch(fromHome: true)
    }
    
    static func openSearch() {
        openSearch(fromHome: false)
    }
    
    static func openSearch(fromHome: Bool) {
        if let dineIn = dineIn, let nav = appVC?.navigationController {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SideMenuTap"), object: nil)
            nav.dismiss(animated: true, completion: nil)
            
            let searchVC: CustomerSearchVC = app.instantiateViewController(withIdentifier: "Search")
                as! CustomerSearchVC
            searchVC.dineIn = dineIn
            searchVC.fromHome = fromHome
            if fromHome {
                nav.pushViewController(searchVC, animated: true)
            } else {
                openLeftMenuVC(searchVC)
            }
        } else {
            openHome()
        }
    }
    
    static func openMenu(for merchant: Merchant) {
        if let nav = appVC?.navigationController {
            let menuVC: CustomerMenuVC = app.instantiateViewController(withIdentifier: "Menu")
                as! CustomerMenuVC
            menuVC.merchant = merchant
            nav.pushViewController(menuVC, animated: true)
        }
    }
    
    static func getMenuList(for merchant: Merchant, menuCategory: MenuCategory) -> CustomerMenuListVC {
        let menuListVC: CustomerMenuListVC = app.instantiateViewController(withIdentifier: "MenuList")
            as! CustomerMenuListVC
        menuListVC.merchant = merchant
        menuListVC.menuCategory = menuCategory
        return menuListVC
    }
    
    static func openPayment(for merchant: Merchant, with order: Order) {
        if let nav = appVC?.navigationController {
            let paymentVC: CustomerPaymentVC = app.instantiateViewController(withIdentifier: "Payment")
                as! CustomerPaymentVC
            paymentVC.merchant = merchant
            paymentVC.order = order
            nav.pushViewController(paymentVC, animated: true)
        }
    }
    
    static func openReceipt(for merchant: Merchant, with order: Order, paymentMethod: PaymentMethod) {
        if let nav = appVC?.navigationController {
            let receiptVC: CustomerReceiptVC = app.instantiateViewController(withIdentifier: "Receipt")
                as! CustomerReceiptVC
            receiptVC.merchant = merchant
            receiptVC.order = order
            receiptVC.paymentMethod = paymentMethod
            nav.pushViewController(receiptVC, animated: true)
        }
    }
    
    static func openOrderSlip(for merchant: Merchant) {
        if let nav = appVC?.navigationController {
            let slipVC: CustomerSlipVC = app.instantiateViewController(withIdentifier: "Slip")
                as! CustomerSlipVC
            slipVC.merchant = merchant
            nav.pushViewController(slipVC, animated: true)
        }
    }
    
    // MARK:
    // MARK: Settings
    static func openSettings() {
        if let _ = appVC?.navigationController {
            let settingsVC = app.instantiateViewController(withIdentifier: "Settings")
            print("settings open \(settingsVC)")
            openLeftMenuVC(settingsVC)
        }
    }
    
    static func openEditProfile() {
        if let nav = appVC?.navigationController {
            let editProfileVC: CustomerEditProfileVC
                = app.instantiateViewController(withIdentifier: "EditProfile") as! CustomerEditProfileVC
            nav.pushViewController(editProfileVC, animated: true)
        }
    }
    
    static func openChangePassword() {
        if let nav = appVC?.navigationController {
            let changePasswordVC: CustomerChangePaswordVC
                = app.instantiateViewController(withIdentifier: "ChangePassword") as! CustomerChangePaswordVC
            nav.pushViewController(changePasswordVC, animated: true)
        }
    }
    
    static func openNotificationSettings() {
        if let nav = appVC?.navigationController {
            let notificationSettingsVC: CustomerNotificationSettingsVC
                = app.instantiateViewController(withIdentifier: "NotificationSettings") as! CustomerNotificationSettingsVC
            nav.pushViewController(notificationSettingsVC, animated: true)
        }
    }
    
    static func openPaymentMethods() {
        openPaymentMethods(selectionCallback: nil)
    }
    
    static func openPaymentMethods(selectionCallback: ((PaymentMethod) -> Void)?) {
        if let nav = appVC?.navigationController {
            let paymentMethodsVC: CustomerPaymentMethodsVC
                = app.instantiateViewController(withIdentifier: "PaymentMethods") as! CustomerPaymentMethodsVC
            paymentMethodsVC.selectionCallback = selectionCallback
            nav.pushViewController(paymentMethodsVC, animated: true)
        }
    }
    
    static func addPaymentMethod(addCallback: @escaping (PaymentMethod) -> Void) {
        if let nav = appVC?.navigationController {
            let addPaymentMethodVC: CustomerPaymentAddMethodVC
                = app.instantiateViewController(withIdentifier: "AddPaymentMethod") as! CustomerPaymentAddMethodVC
            addPaymentMethodVC.addCallback = addCallback
            nav.pushViewController(addPaymentMethodVC, animated: true)
        }
//        editPaymentMethod(nil)
    }
    
    static func showPaymentMethod(_ paymentMethod: PaymentMethod, deleteCallback: @escaping () -> Void) {
        if let nav = appVC?.navigationController {
            let paymentMethodVC: CustomerPaymentMethodVC
                = app.instantiateViewController(withIdentifier: "PaymentMethod") as! CustomerPaymentMethodVC
            paymentMethodVC.paymentMethod = paymentMethod
            paymentMethodVC.deleteCallback = deleteCallback
            nav.pushViewController(paymentMethodVC, animated: true)
        }
    }
    
    static func openAboutUs() {
        if let nav = appVC?.navigationController {
            let aboutUsVC: CustomerAboutUsVC
                = app.instantiateViewController(withIdentifier: "AboutUs") as! CustomerAboutUsVC
            nav.pushViewController(aboutUsVC, animated: true)
        }
    }
    
    // MARK:
    // MARK: Order history
    static func openOrderHistory() {
        if let _ = appVC?.navigationController {
            let orderHistoryVC = app.instantiateViewController(withIdentifier: "OrderHistory")
            openLeftMenuVC(orderHistoryVC)
        }
    }
    
    static func openOrderFeedback(with order: Order, callback: @escaping (() -> Void)) {
        if let nav = appVC?.navigationController {
            let orderFeedbackVC: CustomerOrderFeedbackVC = app.instantiateViewController(withIdentifier: "OrderFeedback") as! CustomerOrderFeedbackVC
            orderFeedbackVC.order = order
            orderFeedbackVC.callback = callback
            nav.pushViewController(orderFeedbackVC, animated: true)
        }
    }
    
    static func openActiveRewards() {
        if let _ = appVC?.navigationController {
            let orderHistoryVC = app.instantiateViewController(withIdentifier: "ActiveRewards")
            openLeftMenuVC(orderHistoryVC)
        }
    }
    #endif
}
