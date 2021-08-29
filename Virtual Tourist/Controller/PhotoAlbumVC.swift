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
        setButtonsUI(enable: false)
        FlickrClient.getPhotosByLocation(lat: pinSelected.latitude, lon: pinSelected.longitude) { response, error in
            guard let response = response else {
                self.setButtonsUI(enable: true)
                showError(message: Errors.flickrServer.localizedDescription, actualVC: self)
                return
            }
            
            for photoStruct in response.photos.photo {
                let mainContext = self.dataController.viewContext
                let imgPath = FlickrClient.getImgPath(photoStruct: photoStruct)
                mainContext.perform {
                    let photoInstance = DownloadImages.savePhotoURL(imgPath: imgPath, context: self.dataController.viewContext)
                    self.pinSelected.addToPhotos(photoInstance)
                    try? mainContext.save()
                }
            }
            self.setButtonsUI(enable: true)
        }
    }
    
    func setButtonsUI(enable: Bool) {
        if enable {
            self.stopIndicatingActivity()
            self.newCollection.isEnabled = true
            self.view.isUserInteractionEnabled = true
        } else {
            newCollection.isEnabled = false
            self.startIndicatingActivity()
            self.view.isUserInteractionEnabled = false
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
        let mainContext = dataController.viewContext
        // Download an image per cell
        if Photo.image == nil && Photo.imageUrl != nil {
            cell.startIndicatingActivity()
            DownloadImages.downloadImage(imgUrl: Photo.imageUrl!) { data, error in
                guard let data = data else {
                    cell.stopIndicatingActivity()
                    DispatchQueue.main.async {
                        cell.errorLabel.text = Errors.photoDownload.localizedDescription
                    }
                    return
                }
                DispatchQueue.main.async {
                    cell.errorLabel.text = ""
                    cell.imageView.image = UIImage(data: data)
                    cell.stopIndicatingActivity()
                }
                mainContext.perform {
                    Photo.image = data
                    try? mainContext.save()
                }
            }
        }
        
        if Photo.image != nil {
            DispatchQueue.main.async {
                cell.errorLabel.text = ""
                cell.imageView.image = UIImage(data: Photo.image!)
                cell.stopIndicatingActivity()
            }
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

