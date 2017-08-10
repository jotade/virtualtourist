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

    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editModeViewHeightConstraint: NSLayoutConstraint!
    
    var editingPins = false {
        didSet{
            editButton.title = editingPins == true ? "Done":"Edit"
        }
    }

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
            
            addAnnotation(pin: pin)
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
        
        if sender.state == UIGestureRecognizerState.began{
            let touchPoint = sender.location(in: mapView)
            let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            let pin = savePin(coordinate: touchCoordinate)
            
            addAnnotation(pin: pin)
        }
    }
    
    func addAnnotation(pin: Pin) {
        
        let annotation = Place(pin: pin, coordinate: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude))
        
        mapView.addAnnotation(annotation)
    }
    
    func savePin(coordinate: CLLocationCoordinate2D ) -> Pin {
        let pin = NSEntityDescription.insertNewObject(forEntityName: "Pin", into: stack.context) as! Pin
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        pin.photoSet = 1
        
        try? stack.saveContext()
        return pin
    }
    
    @IBAction func editAction(_ sender: UIBarButtonItem) {
        
        editingPins = editingPins == false ? true:false
        
        UIView.animate(withDuration: 0.3, animations: {
            self.editModeViewHeightConstraint.constant = self.editModeViewHeightConstraint.constant == 0 ? 60:0
            self.view.layoutIfNeeded()
        })
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
            pinView!.animatesDrop = true
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: false)
        
        let pinAnnotation = view.annotation as! Place
        
        if editingPins {
            
            stack.context.delete(pinAnnotation.pin!)
            mapView.removeAnnotation(pinAnnotation)
            
        } else {
            
            
            
            if pinAnnotation.pin?.photos?.count == 0 {
                
                FlickrDataService.fetchPhotos(for: pinAnnotation.pin!) { (error, photos) in
                    
                    if error == nil{
                        try? stack.saveContext()
                    }else{
                        print(error!.localizedDescription)
                    }
                }
            }
            
            performSegue(withIdentifier: "showPinPhotos", sender: view.annotation)
        }
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let an = sender as! Place
        let vc = segue.destination as! PinPhotosViewController
        vc.pin = an.pin
    }
}

