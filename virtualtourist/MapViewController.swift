//
//  MapViewController.swift
//  virtualtourist
//
//  Created by IM Development on 8/9/17.
//  Copyright © 2017 IM Development. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, UIGestureRecognizerDelegate{

    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addGestureToMap()
        loadAnnotations()
    }
    
    func addGestureToMap() {
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.handleLongPress(_:)))
        longPress.minimumPressDuration = 1
        longPress.delaysTouchesBegan = true
        longPress.delegate = self
        
        mapView.addGestureRecognizer(longPress)
    }
    
    func loadAnnotations() {
        
        let savedPins = fetchPins()
        
        for pin in savedPins {
            
            addAnnotation(coordinate: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude ))
        }
    }
    
    func fetchPins()->[Pin]{
        
        var pins = [Pin]()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        let entityDescription = NSEntityDescription.entity(forEntityName: "Pin", in: stack.context)
        fetchRequest.entity = entityDescription

        do {
            let result = try stack.context.fetch(fetchRequest)
            pins = result as! [Pin]
            
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return pins
    }
    
    
    func handleLongPress(_ sender: UIGestureRecognizer) {
        
        if sender.state == UIGestureRecognizerState.ended { return }
        
        let touchPoint = sender.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)

        addAnnotation(coordinate: touchCoordinate)
    }
    
    func addAnnotation(coordinate: CLLocationCoordinate2D) {
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        //annotation.title = "Event place"
        savePin(coordinate: coordinate)
        
        mapView.addAnnotation(annotation)
    }
    
    func savePin(coordinate: CLLocationCoordinate2D ){
        let pin = NSEntityDescription.insertNewObject(forEntityName: "Pin", into: stack.context) as! Pin
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        
        try? stack.saveContext()
    }
    
    func photosRequest(){
        
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseID = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        if(pinView == nil) {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            //pinView!.canShowCallout = true
            pinView!.animatesDrop = true
        }
        return pinView
    }
    
}

