//
//  CustomerReceiptMapTVC.swift
//  YQueue
//
//  Created by Aleksandr on 06/11/2016.
//  Copyright © 2016 YQueue. All rights reserved.
//

import UIKit
import MapKit
import ReactiveCocoa
import ReactiveSwift
import Result

class CustomerReceiptMapTVC: UITableViewCell, ModelTableViewCellProtocol, MKMapViewDelegate {

    var merchant: Merchant!
    
    @IBOutlet var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: "Merchant")
        if pinView == nil {
            pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Merchant")
        }
        
        pinView?.canShowCallout = false
        pinView?.image = UIImage(named: "pin")
        
        return pinView
    }
    
    var modelChangeSignal: Signal<Void, NoError>?
    var modelChangeObserver: Observer<Void, NoError>?
    var model: ModelTableViewCellModelProtocol? {
        didSet {
            if let model: CustomerReceiptMapVM = model as! CustomerReceiptMapVM? {
                mapView.addAnnotation(model.merchant)
                mapView.region = MKCoordinateRegionMake(model.merchant.coordinate, MKCoordinateSpanMake(0.01, 0.01))
            }
        }
    }
}
