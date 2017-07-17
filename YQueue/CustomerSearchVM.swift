//
//  CustomerSearchVM.swift
//  YQueue
//
//  Created by Toshio on 05/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result
import CoreLocation

class CustomerSearchVM: NSObject, ModelTableViewCellModelProtocol {

    var workingHours: String
    var distance = MutableProperty("unknown")
    var title: String
    var worksNow: Bool
    
    var merchant: Merchant
    var tapSignal: Signal<Void, NoError>
    var tapObserver: Observer<Void, NoError>?
    var reuseIdentifier: String? = nil
    var rowHeight: CGFloat? = 59
    var estimatedRowHeight: CGFloat?
    var tableView: ModelTableView!
    
    init(merchant: Merchant, tap: @escaping () -> Void) {
        self.merchant = merchant
        
        // working hours
        do {
            let cal = Calendar.current
            let df = DateFormatter()
            df.dateFormat = "HH:mm"
            
            var from = DateComponents()
            from.minute = merchant.workingFrom
            
            var to = DateComponents()
            to.minute = merchant.workingTo
            
            workingHours = "\(df.string(from: cal.date(from: from)!)) ~\(df.string(from: cal.date(from: to)!)) hrs"
            
            worksNow = true
            if !(merchant.workingFrom == 0 && merchant.workingTo == 1440) {
                let now = cal.component(.hour, from: Date()) * 60 + cal.component(.minute, from: Date())
                worksNow = now > merchant.workingFrom && now < merchant.workingTo
            }
        }
        
        title = merchant.title!
        
        let (tapSignal, tapObserver) = Signal<Void, NoError>.pipe()
        
        self.tapSignal = tapSignal
        self.tapObserver = tapObserver
        
        super.init()
        tapSignal.observe { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            if self.worksNow {
                tap()
            }
        }
    }
    
    func modelBound() {
        distance <~ Location.shared.lastLocation.signal
            .take(during: reactive.lifetime).map { [weak self] in
                guard let `self` = self else {
                    return ""
                }
                
                if let userLocation: CLLocation = $0 {
                    let location = CLLocation(latitude: self.merchant.latitude,
                                              longitude: self.merchant.longitude)
                    
                    let distanceInKm = location.distance(from: userLocation) / 1000.0
                    return "\(Double(round(100*distanceInKm)/100)) km away"
                } else {
                    return "unknown distance"
                }
            }
    }
}
