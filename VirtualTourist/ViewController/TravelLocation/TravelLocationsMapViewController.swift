//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Marcos Vinicius Goncalves Contente on 25/02/19.
//  Copyright © 2019 Marcos Vinicius Goncalves Contente. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var bottomView: UIView!
    
    var pinAnnotation: MKPointAnnotation? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        navigationItem.rightBarButtonItem = editButtonItem
        bottomView.isHidden = true
        
        if let pins = loadAllPins() {
            showPins(pins)
        }
    }
    
    //MARK: Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PhotoAlbumViewController {
            guard let pin = sender as? Pin else {
                return
            }
            let controller = segue.destination as! PhotoAlbumViewController
            controller.pin = pin
        }
    }
    
    //MARK: Pin
    @IBAction func addPinGesture(_ sender: UILongPressGestureRecognizer) {
        
        let location = sender.location(in: mapView)
        let locCoord = mapView.convert(location, toCoordinateFrom: mapView)
        
        if sender.state == .began {
            
            pinAnnotation = MKPointAnnotation()
            pinAnnotation!.coordinate = locCoord
            
            print("\(#function) Coordinate: \(locCoord.latitude),\(locCoord.longitude)")
            
            mapView.addAnnotation(pinAnnotation!)
            
        } else if sender.state == .changed {
            pinAnnotation!.coordinate = locCoord
        } else if sender.state == .ended {
            
            _ = Pin(latitude: String(pinAnnotation!.coordinate.latitude), longitude: String(pinAnnotation!.coordinate.longitude), CoreDataStack.shared().data
            )
            save()
            
        }
    }
    
    private func loadAllPins() -> [Pin]? {
        var pins: [Pin]?
        do {
            try pins = CoreDataStack.shared().fetchAllPins(entityName: "Pin")
        } catch {
            print("\(#function) error:\(error)")
            showInfo(withTitle: "Error", withMessage: "Error while fetching Pin locations: \(error)")
        }
        return pins
    }
    
    private func loadPin(latitude: String, longitude: String) -> Pin? {
        let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", latitude, longitude)
        var pin: Pin?
        do {
            try pin = CoreDataStack.shared().fetchPin(predicate, entityName: "Pin")
        } catch {
            print("\(#function) error:\(error)")
            showInfo(withTitle: "Error", withMessage: "Error while fetching location: \(error)")
        }
        return pin
    }
    
    func showPins(_ pins: [Pin]) {
        for pin in pins where pin.latitude != nil && pin.longitude != nil {
            let annotation = MKPointAnnotation()
            let latitude = Double(pin.latitude!)!
            let longitude = Double(pin.longitude!)!
            annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
            mapView.addAnnotation(annotation)
        }
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    //MARK: Hidding bottomView
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        bottomView.isHidden = !editing
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard let annotation = view.annotation else {
            return
        }
        
        mapView.deselectAnnotation(annotation, animated: true)
        print("\(#function) latitude \(annotation.coordinate.latitude) longitude \(annotation.coordinate.longitude)")
        
        let latitude = String(annotation.coordinate.latitude)
        let longitude = String(annotation.coordinate.longitude)
        
        if let pin = loadPin(latitude: latitude, longitude: longitude) {
            if isEditing {
                mapView.removeAnnotation(annotation)
                CoreDataStack.shared().data.delete(pin)
                save()
                return
            }
            performSegue(withIdentifier: "PinPhotos", sender: pin)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView!.animatesDrop = true

        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            showInfo(withMessage: "No link defined.")
        }
    }
}
