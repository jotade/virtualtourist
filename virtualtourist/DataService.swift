//
//  DataService.swift
//  virtualtourist
//
//  Created by IM Development on 8/9/17.
//  Copyright © 2017 IM Development. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class DataService {
    
    let instance = DataService()
    var page = 0
    private init(){}
    
    typealias response = (NSError?, [Photo]?) -> Void
    
    static let flickrKey = "ee7b60d0ae2cb5acbe51aa9a75362e51"
    static let invalidAccessErrorCode = 100
    
    
    class func fetchPhotos(for pin:Pin, coordinate: CLLocationCoordinate2D, onCompletion: @escaping response) -> Void {
        
        let urlString: String = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(flickrKey)&accuracy=16&lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&per_page=10&page=2&format=json&nojsoncallback=1"
        let url: NSURL = NSURL(string: urlString)!
        let searchTask = URLSession.shared.dataTask(with: url as URL, completionHandler: {data, response, error -> Void in
            
            if error != nil {
                print("Error fetching photos: \(error!)")
                onCompletion(error as NSError?, nil)
                return
            }
            
            do {
                let resultsDictionary = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: AnyObject]
                guard let results = resultsDictionary else { return }
                
                if let statusCode = results["code"] as? Int {
                    if statusCode == invalidAccessErrorCode {
                        let invalidAccessError = NSError(domain: "com.flickr.api", code: statusCode, userInfo: nil)
                        onCompletion(invalidAccessError, nil)
                        return
                    }
                }
                
                guard let photosContainer = resultsDictionary!["photos"] as? NSDictionary else { return }
                guard let photosArray = photosContainer["photo"] as? [NSDictionary] else { return }

                let flickrPhotos: [Photo] = photosArray.map { flickrPhoto in
                    
                    let photo = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: stack.context) as! Photo
                    
                    photo.photoId = flickrPhoto["id"] as? String ?? ""
                    photo.farm = flickrPhoto["farm"] as? Int16 ?? 0
                    photo.secret = flickrPhoto["secret"] as? String ?? ""
                    photo.server = flickrPhoto["server"] as? String ?? ""
                    photo.title = flickrPhoto["title"] as? String ?? ""
                    photo.photoURL = "https://farm\(photo.farm).staticflickr.com/\(photo.server!)/\(photo.photoId!)_\(photo.secret!)_m.jpg"
                    photo.pin = pin
                    
                    return photo
                }
                
                
                
                onCompletion(nil, flickrPhotos)
                
            } catch let error as NSError {
                print("Error parsing JSON: \(error)")
                onCompletion(error, nil)
                return
            }
            
        })
        searchTask.resume()
    }
}

