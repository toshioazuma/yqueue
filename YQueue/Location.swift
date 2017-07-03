//
//  Location.swift
//  YQueue
//
//  Created by Aleksandr on 21/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import CoreLocation
import ReactiveCocoa
import ReactiveSwift
import Result

class Location: NSObject, CLLocationManagerDelegate {

    static let shared = Location()
    
    private let manager = CLLocationManager()
    var authorizationStatus: CLAuthorizationStatus?
    var lastLocation = MutableProperty<CLLocation?>(nil)
    private var locked = MutableProperty(false)
    
    override init() {
        super.init()
        
        locked.signal.observeValues {
            if $0 {
                // locked
                if let authorizationStatus: CLAuthorizationStatus = self.authorizationStatus,
                    authorizationStatus == .authorizedWhenInUse {
                    self.manager.stopUpdatingLocation()
                }
            } else {
                // free
                self.manager.delegate = self
                self.manager.requestWhenInUseAuthorization()
            }
        }
    }
    
    func request() {
        if let authorizationStatus: CLAuthorizationStatus = authorizationStatus,
            authorizationStatus == .authorizedWhenInUse {
            if #available(iOS 9.0, *) {
                manager.requestLocation()
            } else {
                lastLocation.consumeCurrent()
            }
        }
    }
    
    func free() {
        locked.consume(false)
    }
    
    func lock() {
        locked.consume(true)
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        } else {
            lastLocation.consume(nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location: CLLocation = locations.first {
//            print("RECEIVED LOCATION!")
            lastLocation.consume(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("location manager failed with error \(error)")
    }
}
