//
//  PhotoCollectionCell.swift
//  virtualtourist
//
//  Created by IM Development on 8/9/17.
//  Copyright © 2017 IM Development. All rights reserved.
//

import UIKit

class PhotoCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var photo: Photo?{
        didSet{
            loadImage(photo: photo!)
        }
    }
    
    func loadImage(photo: Photo) {
        
        if let pic = photo.photo {
            
            let image = UIImage(data: pic as Data)
            imageView.image = image
            
        }else{
            
            URLSession.shared.dataTask(with: NSURL(string: photo.photoURL!)! as URL, completionHandler: { (data, response, error) -> Void in
                
                if error != nil {
                    print(error!.localizedDescription)
                    return
                }
                
                photo.photo = data! as NSData
                
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    let image = UIImage(data: data!)
                    self.imageView.image = image
                })
                
            }).resume()
        }
    }
}
