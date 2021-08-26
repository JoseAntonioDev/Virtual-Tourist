//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Jose Antonio Álvarez Vázquez on 23/7/21.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapVC: UIViewController, UIGestureRecognizerDelegate {

    //MARK: Properties
    @IBOutlet var mapView: MKMapView!
    
    let regionKey = "persistedRegion"
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    //MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // First set our saved persistent region
        setPersistedRegion()
        // Then prepare gesture recognizer for the map to work
        addGestureRecognizer()
        // And get our FRC ready
        setUpFetchedResultsController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        // Now populate all the annotations in our mapView
        setUpFetchedResultsController()
        loadFetchedPins()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        fetchedResultsController = nil
    }

    //MARK: Methods
    @IBAction func longPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            // Create location from pressed region
            let annotation = MKPointAnnotation()
            let touchLocation = sender.location(in: self.mapView)
            let location = mapView.convert(touchLocation, toCoordinateFrom: mapView)
            annotation.coordinate = location
            
            handleLocationName(annotation)
        }
    }
    
    
    func handleLocationName(_ annotation: MKPointAnnotation) {
        // Refactor long pressed function
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)) { placemarks, error in
            guard let placemark = placemarks?.first else {
                print("Error finding location name")
                return
            }
            annotation.title = placemark.name ?? "no name"
            annotation.subtitle = placemark.locality
            
            self.savePin(annotation)
        }
    }
    
    func savePin(_ annotation: MKPointAnnotation) {
        // Save the Pin in our Core Data Stack
        let mainContext = self.dataController.viewContext
        let newPin = Pin(context: mainContext)
        mainContext.perform {
            newPin.title = annotation.title
            newPin.subtitle = annotation.subtitle
            newPin.longitude = annotation.coordinate.longitude
            newPin.latitude = annotation.coordinate.latitude
            self.downloadFlickrPhotos(pin: newPin)
            try? mainContext.save()
        }
    }
    
    func downloadFlickrPhotos(pin: Pin) {
        // Download photos before going to the next controller
        FlickrClient.getPhotosByLocation(lat: pin.latitude, lon: pin.longitude) { response, error in
            guard let response = response else {
                showError(message: Errors.flickrServer.localizedDescription, actualVC: self)
                return
            }
            let urlArray = FlickrClient.getImgURL(photoStructs: response.photos.photo)

            DownloadImages.downloadImages(urlArray: urlArray, context: self.dataController.viewContext) { photos, error  in
                for photo in photos {
                    // Add each photo to the pin
                    pin.addToPhotos(photo)
                }
            }
        }
    }
    
    func segueToAlbum(_sender: Any?) {
        // Inject data into the next controller
        let identifier = "PhotoAlbumVC"
        let albumVC = storyboard?.instantiateViewController(identifier: identifier) as! PhotoAlbumVC
        let pinSelected = _sender as! Pin
        albumVC.dataController = self.dataController
        // if we don't have photos associated with the pin selected for any reason, we start the download
        if pinSelected.photos == [] {
            albumVC.startIndicatingActivity()
            downloadFlickrPhotos(pin: pinSelected)
        }
        albumVC.pinSelected = pinSelected
        self.navigationController?.pushViewController(albumVC, animated: true)
    }
    
    fileprivate func addGestureRecognizer() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action:#selector(self.longPressed(_:)))
        longPressGesture.minimumPressDuration = 1
        longPressGesture.delegate = self
        longPressGesture.delaysTouchesBegan = true
        mapView.addGestureRecognizer(longPressGesture)
    }
    
    fileprivate func loadFetchedPins() {
        if let pins = fetchedResultsController.fetchedObjects {
            self.mapView.addAnnotations(pins)
        }
    }
    
    func setPersistedRegion() {
        // Create a region from our persistent dictionary
        if let persistedRegion = UserDefaults.standard.dictionary(forKey: regionKey) as? [String: CLLocationDegrees] {
            let center = CLLocationCoordinate2D(latitude: persistedRegion["latitude"]!, longitude: persistedRegion["longitude"]!)
            let span = MKCoordinateSpan(latitudeDelta: persistedRegion["latitudeDelta"]!, longitudeDelta: persistedRegion["longitudeDelta"]!)
            let region = MKCoordinateRegion(center: center, span: span)
            
            mapView.setRegion(region, animated: true)
        }
    }

    
}

//MARK: - Map Methods
extension TravelLocationsMapVC: MKMapViewDelegate {
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
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        // Save our region in a dictionary to keep it persistent
        let mapRegion = [
                    "latitude" : mapView.region.center.latitude,
                    "longitude" : mapView.region.center.longitude,
                    "latitudeDelta" : mapView.region.span.latitudeDelta,
                    "longitudeDelta" : mapView.region.span.longitudeDelta
                ]
                UserDefaults.standard.set(mapRegion, forKey: regionKey)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        segueToAlbum(_sender: view.annotation)
    }
}

