//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Marcos Vinicius Goncalves Contente on 26/02/19.
//  Copyright © 2019 Marcos Vinicius Goncalves Contente. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout?
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var collectionActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var collectionLoadingStatus: UILabel!
    
    var insertedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var selectedIndexes = [IndexPath]()
    var totalOfPages: Int? = nil
    
    var presentingAlert = false
    var pin: Pin?
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateFlowLayout(view.frame.size)
        mapView.delegate = self
        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        newCollectionButton.setTitle("Generate New Photos", for: .normal)
        newCollectionButton.setTitleColor(.white , for: .normal)
        
        updateStatusLabel("")
        
        guard let pin = pin else {
            return
        }
        showOnTheMap(pin)
        setupFetchedResultControllerWith(pin)
        
        if let photos = pin.photos, photos.count == 0 {
            fetchPhotosFromAPI(pin)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updateFlowLayout(size)
    }
    
    // MARK: Delete photos
    @IBAction func deleteAction(_ sender: Any) {
        for photos in fetchedResultsController.fetchedObjects! {
            CoreDataStack.shared().data.delete(photos)
        }
        save()
        fetchPhotosFromAPI(pin!)
    }
    
    //MARK: Fetching API photos
    private func setupFetchedResultControllerWith(_ pin: Pin) {
        
        let fetch = NSFetchRequest<Photo>(entityName: Photo.entity)
        fetch.sortDescriptors = []
        fetch.predicate = NSPredicate(format: "pin == %@", argumentArray: [pin])
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetch, managedObjectContext: CoreDataStack.shared().data, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        var error: NSError?
        do {
            try fetchedResultsController.performFetch()
        } catch let error1 as NSError {
            error = error1
        }
        
        if let error = error {
            print("\(#function) Error when fetching: \(error)")
        }
    }
    
    private func fetchPhotosFromAPI(_ pin: Pin) {
        
        let latitude = Double(pin.latitude!)!
        let longitude = Double(pin.longitude!)!
        
        startCollectionSpinner()
        
        ApiServices.shared().displayImageFromFlickrBySearch(latitude: latitude, longitude: longitude, totalPages: totalOfPages) { (photosParsed, error) in
            self.performUIUpdatesOnMain {
                
                self.stopCollectionSpinner()
                
            }
            if let photosParsed = photosParsed {
                
                self.totalOfPages = photosParsed.photos.pages
                let totalOfPhotos = photosParsed.photos.photo.count
                self.storePhotos(photosParsed.photos.photo, forPin: pin)
                if totalOfPhotos == 0 {
                    self.updateStatusLabel("No photos available in this location")
                    
                }
            } else if let error = error {
                self.showInfo(withTitle: "ERROR", withMessage: error.localizedDescription)
                self.updateStatusLabel("Error occured, please try again")
            }
        }
    }
    
    //MARK: Update the loading text
    private func updateStatusLabel(_ text: String) {
        self.performUIUpdatesOnMain {
            self.collectionLoadingStatus.text = text
        }
    }
    
    //MARK: Storing photos
    private func storePhotos(_ photos: [FlickrPhoto], forPin: Pin) {
        func showErrorMessage(msg: String) {
            showInfo(withTitle: "ERROR", withMessage: msg)
        }
        
        for photo in photos {
            performUIUpdatesOnMain {
                if let url = photo.url {
                    _ = Photo(title: photo.title, imageUrl: url, forPin: forPin, context: CoreDataStack.shared().data)
                    self.save()
                }
            }
        }
    }
    
    //MARK: Loading photos
    private func loadPhotos(using pin: Pin) -> [Photo]? {
        let predicate = NSPredicate(format: "pin == %@", argumentArray: [pin])
        var photos: [Photo]?
        do {
            try photos = CoreDataStack.shared().fetchPhotos(predicate, entityName: Photo.entity)
        } catch {
            showInfo(withTitle: "ERROR", withMessage: "Error while loading photos from disk: \(error)")
        }
        return photos
    }
    
    //MARK: Displaying photos
    private func showOnTheMap(_ pin: Pin) {
        
        let latitude = Double(pin.latitude!)!
        let longitude = Double(pin.longitude!)!
        let locCoord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = locCoord
        
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(annotation)
        mapView.setCenter(locCoord, animated: true)
    }
    
    //MARK: FlowLayout set up
    private func updateFlowLayout(_ withSize: CGSize) {
        
        let landscape = withSize.width > withSize.height
        
        let space: CGFloat = landscape ? 1 : 1
        let items: CGFloat = landscape ? 3 : 4
        
        let dimension = (withSize.width - ((items + 1) * space)) / items
        
        collectionViewFlowLayout?.minimumInteritemSpacing = space
        collectionViewFlowLayout?.minimumLineSpacing = space
        collectionViewFlowLayout?.itemSize = CGSize(width: dimension, height: dimension)
        collectionViewFlowLayout?.sectionInset = UIEdgeInsets(top: space, left: space, bottom: space, right: space)
    }
    
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            newCollectionButton.setTitle("Click to Delete Pins", for: .normal)
            newCollectionButton.setTitleColor(.white , for: .normal)
        } else {
            newCollectionButton.setTitle("More Collections", for: .normal)
            newCollectionButton.setTitleColor(.white , for: .normal)
        }
    }
}

extension PhotoAlbumViewController {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
    }
    
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?) {
        
        switch (type) {
        case .insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .update:
            updatedIndexPaths.append(indexPath!)
            break
        case .move:
            print("This feature is disabled")
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath])
            }
            
        }, completion: nil)
    }
    
}


extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sectionInfo = self.fetchedResultsController.sections?[section] {
            return sectionInfo.numberOfObjects
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageViewCell
        cell.imageViewCell.image = nil
        
        startCellSpinner(using: cell)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let image = fetchedResultsController.object(at: indexPath)
        let imageCell = cell as! ImageViewCell
        imageCell.imageUrl = image.imageUrl!
        configImage(use: imageCell, toAdd: image, as: collectionView, index: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let thisImage = fetchedResultsController.object(at: indexPath)
        CoreDataStack.shared().data.delete(thisImage)
        save()
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying: UICollectionViewCell, forItemAt: IndexPath) {
        
        if collectionView.cellForItem(at: forItemAt) == nil {
            return
        }
        
        let image = fetchedResultsController.object(at: forItemAt)
        if let imageUrl = image.imageUrl {
            ApiServices.shared().cancelDownload(imageUrl)
        }
    }
    
    // MARK: Configuring image
    
    private func configImage(use cell: ImageViewCell, toAdd: Photo, as: UICollectionView, index: IndexPath) {
        if let imageData = toAdd.image {
            
            stopCellSpinner(using: cell)
            
            cell.imageViewCell.image = UIImage(data: Data(referencing: imageData))
        } else {
            if let imageUrl = toAdd.imageUrl {
                
                startCellSpinner(using: cell)
                
                ApiServices.shared().downloadImage(imageUrl: imageUrl) { (data, error) in
                    if let _ = error {
                        self.performUIUpdatesOnMain {
                            
                            stopCellSpinner(using: cell)
                            
                            self.errorForImageUrl(imageUrl)
                        }
                        return
                    } else if let data = data {
                        self.performUIUpdatesOnMain {
                            
                            if let currentCell = self.collectionView.cellForItem(at: index) as? ImageViewCell {
                                if currentCell.imageUrl == imageUrl {
                                    currentCell.imageViewCell.image = UIImage(data: data)
                                    
                                    stopCellSpinner(using: cell)
                                }
                            }
                            toAdd.image = NSData(data: data)
                            DispatchQueue.global(qos: .background).async {
                                self.save()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func errorForImageUrl(_ imageUrl: String) {
        if !self.presentingAlert {
            self.showInfo(withTitle: "ERROR", withMessage: "Error while fetching photo for URL: \(imageUrl)", action: {
                self.presentingAlert = false
            })
        }
        self.presentingAlert = true
    }
    
    //MARK: Collection spinners set up
    
    func startCollectionSpinner() {
        self.collectionActivityIndicator.isHidden = false
        self.collectionActivityIndicator.startAnimating()
        self.updateStatusLabel("LOADING....")
    }
    
    func stopCollectionSpinner() {
        self.collectionActivityIndicator.stopAnimating()
        self.collectionActivityIndicator.isHidden = true
        self.collectionLoadingStatus.text = ""
    }
    
}

//MARK: Cell spinners set up
func startCellSpinner(using cell: ImageViewCell) {
    cell.imageActivityIndicator.isHidden = false
    cell.imageActivityIndicator.startAnimating()
}

func stopCellSpinner(using cell: ImageViewCell) {
    cell.imageActivityIndicator.stopAnimating()
    cell.imageActivityIndicator.isHidden = true
}
