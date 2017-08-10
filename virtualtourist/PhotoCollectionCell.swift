//
//  PhotoCollectionCell.swift
//  virtualtourist
//
//  Created by IM Development on 8/9/17.
//  Copyright © 2017 IM Development. All rights reserved.
//

import UIKit

class PhotoCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var selectedView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageView: UIImageView!
    
    var photo: Photo?{
        didSet{
            loadImage(photo: photo!)
        }
    }
    
    func toggleSelected() -> Bool {
        selectedView.isHidden = selectedView.isHidden ? false:true
        return selectedView.isHidden
    }
    
    func loadImage(photo: Photo) {
        
        if let pic = photo.photo {
            
            let image = UIImage(data: pic as Data)
            imageView.image = image
            
        }else{
            activityIndicator.isHidden = false
            URLSession.shared.dataTask(with: NSURL(string: photo.photoURL!)! as URL, completionHandler: { (data, response, error) -> Void in
                
                if error != nil {
                    print(error!.localizedDescription)
                    return
                }
                
                photo.photo = data! as NSData
                
                
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    let image = UIImage(data: data!)
                    self.imageView.image = image
                    self.activityIndicator.isHidden = true
                })
                
            }).resume()
        }
    }
    
    override func prepareForReuse() {
        imageView.image = UIImage(named: "VirtualTourist")
        activityIndicator.isHidden = true
        selectedView.isHidden = true
    }
}
