//
//  PinPhotosViewController.swift
//  virtualtourist
//
//  Created by IM Development on 8/9/17.
//  Copyright © 2017 IM Development. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PinPhotosViewController: UIViewController{
    
    @IBOutlet weak var collectionButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    var blockOperations: [BlockOperation] = []
    var pin: Pin?
    
    var selectedPhotos = [Int:Photo](){
        didSet{
            if selectedPhotos.count > 0 {
                collectionButton.title = "Remove Selected Pictures"
            }else{
                collectionButton.title = "New Collection"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        attempFetch()
        configureLayout()
        configureMap()
    }
    
    func configureMap() {
        
        let location = CLLocation(latitude: pin!.latitude, longitude: pin!.longitude)
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin!.latitude, longitude: pin!.longitude)
        mapView.addAnnotation(annotation)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func configureLayout() {
        
        let space:CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        collectionView.collectionViewLayout = flowLayout
    }
    
    func attempFetch(){
        
        setFetchedResults()
        
        do{
            try self.fetchedResultsController.performFetch()
        }catch{
            let error = error as NSError
            print("\(error), \(error.userInfo)")
        }
    }
    
    func setFetchedResults(){
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let predicate = NSPredicate(format: "pin == %@", pin!)
        fetchRequest.predicate = predicate
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = self
        fetchedResultsController = controller
    }
    
    @IBAction func collectionButtonAction(_ sender: UIBarButtonItem) {
        
        if selectedPhotos.count > 0 {
            
            for (_,photo) in selectedPhotos {
                stack.context.delete(photo)
            }
            
            try? stack.saveContext()
            
            selectedPhotos = [:]
            
        }else{
            
            for photo in fetchedResultsController.fetchedObjects as! [Photo] {
                stack.context.delete(photo)
            }
            
            pin!.photoSet = pin!.photoSet + 1
            
            FlickrDataService.fetchPhotos(for: pin!) { (error, photos) in
                
                if error == nil{
                    try? stack.saveContext()
                }
            }
        }
    }
    
    deinit {
        for operation: BlockOperation in blockOperations {
            operation.cancel()
        }
        
        blockOperations.removeAll(keepingCapacity: false)
    }
}

extension PinPhotosViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if let photo = fetchedResultsController.object(at: indexPath) as? Photo {
            
            let cell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionCell
            
            if !cell.toggleSelected() {
                
                selectedPhotos[indexPath.row] = photo
            }else{
                
                selectedPhotos.removeValue(forKey: indexPath.row)
            }
        }
    }
}

extension PinPhotosViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCollectionCell
        if let photo = fetchedResultsController.object(at: indexPath) as? Photo{
            cell.photo = photo
        }
        return cell
    }
}

extension PinPhotosViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if type == NSFetchedResultsChangeType.insert {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    
                    if let this = self {
                        
                        this.collectionView!.insertItems(at: [newIndexPath!])
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.update {

            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    
                    if let this = self {
                        
                        this.collectionView!.reloadItems(at: [indexPath!])
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.move {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    
                    if let this = self {
                        
                        this.collectionView!.moveItem(at: indexPath!, to: newIndexPath!)
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.delete {

            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    
                    if let this = self {
                        
                        this.collectionView!.deleteItems(at: [indexPath!])
                    }
                })
            )
        }
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        
        if type == NSFetchedResultsChangeType.insert {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    
                    if let this = self {
                        
                        this.collectionView!.insertSections(NSIndexSet(index: sectionIndex) as IndexSet)
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.update {

            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    
                    if let this = self {
                        
                        this.collectionView!.reloadSections(NSIndexSet(index: sectionIndex) as IndexSet)
                    }
                })
            )
        }
            
        else if type == NSFetchedResultsChangeType.delete {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    
                    if let this = self {
                        this.collectionView!.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet)
                    }
                })
            )
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        collectionView!.performBatchUpdates({ () -> Void in
            
            for operation: BlockOperation in self.blockOperations {
                operation.start()
            }
        }, completion: { (finished) -> Void in
            self.blockOperations.removeAll(keepingCapacity: false)
        })
    }
    
    
}
