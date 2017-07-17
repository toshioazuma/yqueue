//
//  CustomerSearchVC.swift
//  YQueue
//
//  Created by Toshio on 05/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import MapKit
import ReactiveCocoa
import ReactiveSwift
import Result
import MBProgressHUD

class CustomerSearchVC: AppVC, MKMapViewDelegate {
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchFieldHeight: NSLayoutConstraint!
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.showsUserLocation = true
        }
    }
    @IBOutlet weak var toggleButton: UIButton! {
        didSet {
            toggleButton.layer.cornerRadius = 5
            toggleButton.layer.borderColor = UIColor(red: 0, green: 190.0/255.0, blue: 98.0/255.0, alpha: 1).cgColor
            toggleButton.layer.borderWidth = 1.5
        }
    }
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var listViewWrapper: UIView!
    @IBOutlet weak var tableView: ModelTableView!
    @IBOutlet weak var toggleButtonTopOffset: NSLayoutConstraint!
    @IBOutlet weak var tableViewTopOffset: NSLayoutConstraint!

    var listView = true
    var dineIn = false
    var fromHome = false
    var allMerchants = Array<Merchant>()
    var merchants = Array<Merchant>()
    
    deinit {
        print("searchvc deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Search Restaurants"
        
        Location.shared.lastLocation.signal
            .take(first: 1)
            .observeValues { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                if let location: CLLocation = $0 {
                    let distanceInMeters = 35000.0
                    self.mapView.region = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                             distanceInMeters,
                                                                             distanceInMeters)
                }
        }
        Location.shared.request()
        
        searchTextField.reactive.continuousTextValues.observe { [weak self] in
            guard let `self` = self else {
                return
            }
            
            var searchText: String? = $0.value!
            if searchText == nil {
                searchText = ""
            }
            
            self.showMerchants(withSearchText: searchText!)
        }
        
        toggle()
        toggleButton.reactive.trigger(for: .touchUpInside).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.toggle()
        }
        
        locationButton.reactive.trigger(for: .touchUpInside).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            let distanceInMeters = 5000.0
            self.mapView.region = MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.coordinate,
                                                                     distanceInMeters,
                                                                     distanceInMeters)
//
//            let centerBlock: (CLLocation) -> Void = {
//                let distanceInMeters = 5000.0
//                self.mapView.region = MKCoordinateRegionMakeWithDistance($0.coordinate,
//                                                                         distanceInMeters,
//                                                                         distanceInMeters)
//            }
//            
//            if let status: CLAuthorizationStatus = Location.shared.authorizationStatus {
//                if status == .authorizedWhenInUse {
//                    Location.shared.lastLocation.signal
//                        .take(first: 1)
//                        .observeValues {
//                            if let location: CLLocation = $0 {
//                                centerBlock(location)
//                            }
//                    }
//                    Location.shared.request()
//                } else {
//                    UIAlertController.show(okAlertIn: self,
//                                           withTitle: "Warning",
//                                           message: "Couldn't get your location. Please allow YQueue to use your location in system settings.")
//                }
//            } else {
//                Storyboard.showProgressHUD()
//                Location.shared.lastLocation.signal
//                    .take(first: 1)
//                    .observeValues { [weak self] in
//                        Storyboard.hideProgressHUD()
//                        
//                        guard let `self` = self else {
//                            return
//                        }
//                        if let location: CLLocation = $0 {
//                            centerBlock(location)
//                        } else {
//                            UIAlertController.show(okAlertIn: self,
//                                                   withTitle: "Warning",
//                                                   message: "Couldn't get your location. Please allow YQueue to use your location in system settings.")
//                        }
//                }
//            }
        }
        
        addRightButton(image: UIImage(named: "search")!, addSpace: true).observeValues { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.searchFieldHeight.constant = self.searchFieldHeight.constant == 0 ? 46 : 0
        }
    }
    
    private var dineInAutoSuggestionPlaced = false
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if dineIn && fromHome && !dineInAutoSuggestionPlaced {
            dineInAutoSuggestionPlaced = true
            Storyboard.showProgressHUD()
            
            let regionInsideDistance = 50.0
            let regionInside = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate,
                                                                  regionInsideDistance,
                                                                  regionInsideDistance)
            let regionNearbyDistance = 1000.0
            let regionNearby = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate,
                                                                  regionNearbyDistance,
                                                                  regionNearbyDistance)
            
            let userLocation = CLLocation(latitude: self.mapView.userLocation.coordinate.latitude,
                                          longitude: self.mapView.userLocation.coordinate.longitude)
            Api.merchants.list(in: regionInside)
                .observe(on: QueueScheduler.main)
                .observeValues { [weak self] in
                    if $0.count > 1 {
                        Storyboard.hideProgressHUD()
                        
                        var distances = [Merchant:Double]()
                        for merchant in $0 {
                            let merchantLocation = CLLocation(latitude: merchant.latitude,
                                                              longitude: merchant.longitude)
                            let distance = merchantLocation.distance(from: userLocation)
                            distances[merchant] = distance
                        }
                        
                        let closestMerchant = $0.sorted(by: {
                            return distances[$0]! < distances[$1]!
                        }).first!
                        
                        if let `self` = self {
                            self.merchantChosen(closestMerchant)
                        }
                    } else if $0.count == 1 {
                        Storyboard.hideProgressHUD()
                        if let `self` = self {
                            self.merchantChosen($0[0])
                        }
                    } else {
                        Api.merchants.list(in: regionNearby)
                            .observe(on: QueueScheduler.main)
                            .observeValues { [weak self] in
                                Storyboard.hideProgressHUD()
                                if $0.count == 0 {
                                    Storyboard.openSearchTutorial()
                                    return
                                }
                                
                                if $0.count == 1 {
                                    // TEMPORARY
                                    if let `self` = self {
                                        self.merchantChosen($0[0])
                                    }
//                                    Storyboard.openMenu(for: $0[0])
                                    return
                                }
                                
                                var distances = [Merchant:Double]()
                                for merchant in $0 {
                                    let merchantLocation = CLLocation(latitude: merchant.latitude,
                                                                      longitude: merchant.longitude)
                                    let distance = merchantLocation.distance(from: userLocation)
                                    distances[merchant] = distance
                                }
                                
                                let closestMerchants = $0.sorted(by: {
                                    return distances[$0]! < distances[$1]!
                                }).prefix(5)
                                
                                let alert = UIAlertController(title: nil,
                                                              message: "We've determined next restaurants near to you. Please choose what restaurant you're in or go back to search.",
                                                              preferredStyle: .actionSheet)
                                for merchant in closestMerchants {
                                    alert.addAction(UIAlertAction(title: merchant.title,
                                                                  style: .default,
                                                                  handler: { [weak self] _ in
                                                                    if let `self` = self {
                                                                        self.merchantChosen(merchant)
                                                                    }
                                    }))
                                }
                                
                                alert.addAction(UIAlertAction(title: "Cancel",
                                                              style: .cancel,
                                                              handler: nil))
                                
                                if let `self` = self {
                                    self.present(alert, animated: true, completion: nil)
                                }
                        }
                    }
            }
        } else {
            Storyboard.openSearchTutorial()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Location.shared.free()
        if dineInAutoSuggestionPlaced {
            Storyboard.openSearchTutorial()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Location.shared.lock()
    }
    
    private var initiallyToggled = false
    private func toggle() {
        toggleButton.isSelected = !toggleButton.isSelected
        listView = !listView
        locationButton.isHidden = listView
        
        showMerchants(withSearchText: searchTextField.text!)
        
        if !initiallyToggled {
            initiallyToggled = true
            listViewWrapper.isHidden = !listView
            self.view.layoutIfNeeded() // calc sizes
        } else {
            var speed: CGFloat = 300
            
            let toggleButtonDistance = toggleButtonTopOffset.constant * 2
            let duration = Animation.moveOffset(forView: self.view, offset: toggleButtonTopOffset, delta: -toggleButtonDistance, speed: speed)
            Animation.moveOffset(forView: self.view, offset: toggleButtonTopOffset, delta: toggleButtonDistance, speed: speed, delay: duration)
            
            let tableViewDistance = tableView.frame.size.height * 2
            speed = speed * tableViewDistance/toggleButtonDistance / 1.5
            if listView {
                // hide before animation
                tableViewTopOffset.constant = tableViewTopOffset.constant - tableViewDistance
                self.view.layoutIfNeeded()
            } else {
                // animate fade out
                _ = Animation.moveOffset(forView: self.view, offset: tableViewTopOffset, delta: -tableViewDistance, speed: speed)
            }
            Animation.moveOffset(forView: self.view, offset: tableViewTopOffset, delta: tableViewDistance, speed: speed, delay: duration)
            
            if listView {
                listViewWrapper.isHidden = false
//                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//                    self.tableView.reloadData()
//                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    
                    self.listViewWrapper.isHidden = true
                }
            }
        }
    }
    
    private func merchantChosen(_ merchant: Merchant) {
        var worksNow = true
        if !(merchant.workingFrom == 0 && merchant.workingTo == 1440) {
            let cal = Calendar.current
            let now = cal.component(.hour, from: Date()) * 60 + cal.component(.minute, from: Date())
            worksNow = now > merchant.workingFrom && now < merchant.workingTo
        }
        
        if !worksNow {
            let cal = Calendar.current
            let df = DateFormatter()
            df.dateFormat = "HH:mm"
            
            var from = DateComponents()
            from.minute = merchant.workingFrom
            
            UIAlertController.show(okAlertIn: self,
                                   withTitle: "Warning",
                                   message: "Unfortunately this restaurant is closed now and will be open at \(df.string(from: cal.date(from: from)!))")
            return
        }
        
        Basket.shared.clear()
        if dineIn {
            Storyboard.openOrderSlip(for: merchant)
        } else {
            Storyboard.openMenu(for: merchant)
        }
    }

    private func showMerchants(withSearchText searchText: String) {
        mapView.removeAnnotations(merchants)
        
        var merchantsToShow = Array<Merchant>()
        var models = Array<CustomerSearchVM>()
        for merchant in allMerchants {
            if searchText.characters.count == 0 || (merchant.title?.lowercased().contains(searchText.lowercased()))! {
                merchantsToShow.append(merchant)
                
                mapView.addAnnotation(merchant)
                models.append(CustomerSearchVM(merchant: merchant, tap: { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    
                    self.merchantChosen(merchant)
                }))
            }
        }
        
        merchants = merchantsToShow
        tableView.models = models
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        Api.merchants.list(in: mapView.region).observe(on: QueueScheduler.main).observe { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.allMerchants = $0.value!
            self.showMerchants(withSearchText: self.searchTextField.text!)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let merchant: Merchant = annotation as? Merchant else {
            return nil
        }
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: "Merchant")
        if pinView == nil {
            pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Merchant")
        }
        
        pinView?.canShowCallout = false
        pinView?.image = UIImage(named: "pin")
        
        var titleLabel: UILabel? = pinView?.viewWithTag(100) as? UILabel
        if titleLabel == nil {
            titleLabel = UILabel(frame: CGRect(x: 39, y: 0, width: 100, height: 44))
            titleLabel?.textColor = UIColor(white: 39.0/255.0, alpha: 1.0)
            titleLabel?.font = UIFont.boldSystemFont(ofSize: 11)
            titleLabel?.numberOfLines = 3
            titleLabel?.tag = 100
            pinView?.addSubview(titleLabel!)
            pinView?.sendSubview(toBack: titleLabel!)
        }
        
        titleLabel?.text = merchant.title
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let merchant: Merchant = view.annotation as? Merchant {
            merchantChosen(merchant)
        }
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
}
