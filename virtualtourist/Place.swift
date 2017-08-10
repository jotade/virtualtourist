//
//  Place.swift
//  virtualtourist
//
//  Created by IM Development on 8/9/17.
//  Copyright © 2017 IM Development. All rights reserved.
//

import MapKit
import CoreData

class Place: NSObject, MKAnnotation {
    var pin: Pin?
    var coordinate: CLLocationCoordinate2D
    
    init(pin: Pin, coordinate: CLLocationCoordinate2D) {
        
        self.pin = pin
        self.coordinate = coordinate
    }
}
