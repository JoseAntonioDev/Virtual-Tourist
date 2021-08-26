//
//  PhotoAlbumVC.swift
//  Virtual Tourist
//
//  Created by Jose Antonio Álvarez Vázquez on 23/7/21.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumVC: UIViewController {
    
    //MARK: Properties
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var emptyText: UILabel!
    @IBOutlet var newCollection: UIBarButtonItem!
    
    // Injected data & Core Stack
    var pinSelected: Pin!
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    let reuseId = "CollectionCell"
    
    //MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpFetchedResultsController()
        setMapUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        mapView.removeAnnotation(pinSelected)
        fetchedResultsController = nil
    }
    
    //MARK: Methods
    @IBAction func newCollection(_ sender: Any) {
        reloadPhotos()
    }
    
    // Prepare our map UI with the pin injected
    fileprivate func setMapUI() {
        mapView.isUserInteractionEnabled = false
        mapView.addAnnotation(pinSelected)
        mapView.showAnnotations([pinSelected], animated: true)
        mapView.camera.centerCoordinate = pinSelected.coordinate
    }
    
    // Delete all the album if exists & save context
    fileprivate func deletePhotos() {
        if pinSelected.photos?.count != 0 {
            let mainContext = dataController.viewContext
            if let photos = fetchedResultsController.fetchedObjects {
                for photo in photos {
                    mainContext.perform {
                        mainContext.delete(photo)
                        try? mainContext.save()
                    }
                }
            }
        }
    }
    
    fileprivate func reloadPhotos() {
        // First delete our album & disable newCollection button until download has finished
        deletePhotos()
        startIndicatingActivity()
        newCollection.isEnabled = false
        FlickrClient.getPhotosByLocation(lat: pinSelected.latitude, lon: pinSelected.longitude) { response, error in
            if response?.stat == "ok" {
                let urlArray = FlickrClient.getImgURL(photoStructs: response!.photos.photo)
                let mainContext = self.dataController.viewContext
                mainContext.perform {
                //Download images & save context
                    DownloadImages.downloadImages(urlArray: urlArray, context: self.dataController.viewContext) { photos, error in
                        for photo in photos {
                            self.pinSelected.addToPhotos(photo)
                        }
                    }
                    
                    try? mainContext.save()
                }
                self.stopIndicatingActivity()
                self.collectionView.reloadData()
                self.newCollection.isEnabled = true
            } else {
                showError(message: Errors.flickrServer.localizedDescription, actualVC: self)
                self.stopIndicatingActivity()
                self.collectionView.reloadData()
                self.newCollection.isEnabled = true
                return
            }
        }
    }
    
}

//MARK: - Map Methods
extension PhotoAlbumVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .blue
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
}

//MARK: - CollectionView Methods
extension PhotoAlbumVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Check if the download has finished
        if (activityIndicator.isAnimating) && (fetchedResultsController.sections?[section].numberOfObjects != 0) {
            stopIndicatingActivity()
            collectionView.reloadData()
        }
        
        // Check if our album is empty
        if (fetchedResultsController.sections?[section].numberOfObjects == 0) {
            self.emptyText.text = "There is no photos yet!😯"
        } else {
            emptyText.text = nil
        }
        
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let Photo = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseId, for: indexPath) as! CollectionCell
        
        // Set placeholder while downloading state
        if activityIndicator.isAnimating {
            cell.placeholderLabel.text = "Downloading"
        }
        
        // Configure cell
        if let photoData = Photo.image {
            cell.placeholderLabel.text = ""
            cell.imageView.image = UIImage(data: photoData)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Delete selected photo from Core Stack
        let photoToErase = fetchedResultsController.object(at: indexPath)
        let mainContext = dataController.viewContext
        mainContext.perform {
            mainContext.delete(photoToErase)
            try? mainContext.save()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width  = (view.frame.width-20)/3
        return CGSize(width: width, height: width)
    }
}

