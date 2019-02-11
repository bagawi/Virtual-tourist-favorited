//
//  CollectionViewController.swift
//  VirtualTourist
//
//  Created by Mohammed Albaqawi on 1/20/19.
//  Copyright © 2019 Mohd. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class CollectionViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var noImageLable: UILabel!
    
    
    var dataController:DataController!
    var pin: Pin!
    
    public var photosUrlArray = [URL]()
    var selectedPhotos = [IndexPath]()
    private var blockOperations: [BlockOperation] = []
    
    
    
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    
    func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", self.pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            
        } catch {
            fatalError("No fetch \(error.localizedDescription)")
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        newCollectionButton.isEnabled = false
        
        setupFetchedResultsController()
        if self.fetchedResultsController.fetchedObjects?.count == 0 {
            getPhotosFromFlikr()
        }
        
        createAnnotation()
        setFlowLayout()
        
        collectionView.allowsMultipleSelection = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        
    }
    func getPhotosFromFlikr(){
        
        Api.sharedInstance().bringPhotos(latitude: pin.latitude, longitude: pin.longitude) { (result, photoInfo, errorString)   in
            
            if result {
                
                if errorString == nil {
                    
                    DispatchQueue.main.async {
                        self.noImageLable.isHidden = true
                    }
                    if let photo = photoInfo as? [PhotoParse] {
                        
                        for i in photo {
                            
                            self.photosUrlArray.append(URL(string: i.url_m)!)
//                            DispatchQueue.main.async {
//                                self.collectionView.reloadData()
//                            }
                            self.downloadImages({ (data) in

                            })

                            
                        }
                    }
                }else {
                    DispatchQueue.main.async {
                        self.noImageLable.isHidden = false
                        self.noImageLable.text = errorString
                    }
                }
                
            }
        }
    }
    
    func setFlowLayout(){
        let space:CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    @IBAction func newCollection(_ sender: UIButton) {
        
        if sender.currentTitle == "New Collection" {
            
            guard let fetchedResults = self.fetchedResultsController.fetchedObjects else {
                return
            }
            
            photosUrlArray.removeAll()
            
            for i in fetchedResults {
                DataController.shared.viewContext.delete(i)
                try? DataController.shared.viewContext.save()
            }
            
            getPhotosFromFlikr()
            
        } else if sender.currentTitle == "Remove Selected Pictures" {
            
            sender.setTitle("New Collection", for: .normal)
            
            deletePhotos()
            
        }
        
    }
    
    func createAnnotation(){
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
        self.mapView.addAnnotation(annotation)
        let coredinate:CLLocationCoordinate2D = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
        let region = MKCoordinateRegion(center: coredinate, span: span)
        self.mapView.setRegion(region, animated: true)
        
    }
    
    func updateUI(cell:PhotosCollectionViewCell, status:Bool) {
        
        if status == false {
            cell.activityIndicator.isHidden = false
            cell.activityIndicator.startAnimating()
            
        } else {
            cell.activityIndicator.stopAnimating()
            cell.activityIndicator.isHidden = true
            
        }
    }
    
    func downloadImages(_ complition : @escaping (_ data : Data?) -> Void) {
       
            
            for url in photosUrlArray {
                
                let dataTask = URLSession.shared.dataTask(with: url) {
                    (data, response, error) in
                    
                    if error == nil {
                        if let data = data {
                            
                            self.addPhotosToCoreData(data,url)
                            complition(data)
                            DispatchQueue.main.async {
                                
                            
                          //  self.collectionView.reloadData()
                            }
                        }
                        
                    }else {
                        debugPrint()
                    }
                }
                dataTask.resume()
                
            }
        
        
        
    }
    
    func addPhotosToCoreData(_ data: Data,_ url: URL) {
        let photo = Photo(context: DataController.shared.viewContext)
        
        photo.imageData = data
        photo.creationDate =  Date()
        photo.pin = pin
        photo.imageUrl = url.absoluteString
        
        do
        {
            try DataController.shared.viewContext.save()
        }
        catch
        {
            
            print(error)
        }
        
    }
    
    func deletePhotos() {
        print("delete items")
        var photosToDelete: [Photo] = [Photo]()
        
        for i in selectedPhotos {
            photosToDelete.append(fetchedResultsController.object(at: i))
        }
        
        for i in photosToDelete {
            DataController.shared.viewContext.delete(i)
            try? DataController.shared.viewContext.save()
        }
        
        selectedPhotos.removeAll()
        
    }
    
    
    deinit {
        
        for operation: BlockOperation in blockOperations {
            operation.cancel()
        }
        
        blockOperations.removeAll(keepingCapacity: false)
    }
    
    
}


extension CollectionViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        
        if let sectionInfo = self.fetchedResultsController.sections?[section], sectionInfo.numberOfObjects > 0 {
            return sectionInfo.numberOfObjects
        }
        return self.fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photosCell", for: indexPath) as? PhotosCollectionViewCell
            else {
                return UICollectionViewCell()
        }
        cell.activityIndicator.startAnimating()
        if self.fetchedResultsController.fetchedObjects?.count == 0 {
            getPhotosFromFlikr()
        }
        cell.selectedView.isHidden = true
         self.updateUI(cell: cell, status: false)
        cell.activityIndicator.startAnimating()
              let arrayData = self.fetchedResultsController.fetchedObjects!
                        if !arrayData.isEmpty {
                            cell.activityIndicator.startAnimating()
                            for photo in arrayData {
                                DispatchQueue.main.async {
                                    
                                    cell.imageFlikr.image =  UIImage(data: arrayData[indexPath.row].imageData!)
                                    collectionView.reloadData()
                                    
                                }
                                
                                
                            }
                            cell.activityIndicator.stopAnimating()
                    }
        
        
        
        
        
  
        newCollectionButton.isEnabled = true
        //   self.updateUI(cell: cell, status: true)
        return cell
        
    }
}

extension CollectionViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! PhotosCollectionViewCell
        
        cell.selectedView.isHidden = false
        newCollectionButton.setTitle("Remove Selected Pictures", for: .normal)
        
        selectedPhotos.append(indexPath)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! PhotosCollectionViewCell
        
        cell.selectedView.isHidden = true
        
        selectedPhotos.remove(at: indexPath.startIndex)
        
        if selectedPhotos.count == 0 {
            newCollectionButton.setTitle("New Collection", for: .normal)
        }
    }
    
}

extension CollectionViewController:NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOperations.removeAll(keepingCapacity: false)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        
        let op: BlockOperation
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            op = BlockOperation { self.collectionView.insertItems(at: [newIndexPath]) }
            
        case .delete:
            guard let indexPath = indexPath else { return }
            op = BlockOperation { self.collectionView.deleteItems(at: [indexPath]) }
        case .move:
            guard let indexPath = indexPath,  let newIndexPath = newIndexPath else { return }
            op = BlockOperation { self.collectionView.moveItem(at: indexPath, to: newIndexPath) }
        case .update:
            guard let indexPath = indexPath else { return }
            op = BlockOperation { self.collectionView.reloadItems(at: [indexPath]) }
        }
        
        blockOperations.append(op)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({
            self.blockOperations.forEach { $0.start() }
        }, completion: { finished in
            self.blockOperations.removeAll(keepingCapacity: false)
        })
    }
    
    
}
