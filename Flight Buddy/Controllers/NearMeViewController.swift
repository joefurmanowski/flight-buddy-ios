//
//  NearMeViewController.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 11/29/22.
//

import UIKit
import CoreLocation
import MapKit

class NearMeViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    let locationManager = CLLocationManager()
    let airportsModel = AirportsModel.sharedInstance
    
    @IBOutlet weak var stepper: UIStepper!
    
    @IBOutlet weak var mapView: MKMapView!
    
    var requestedDistance: Double = 25.0
    var selectedAirport: Airport?
    
    @IBOutlet weak var distanceLabel: UILabel!
    
    var airportAnnotations: [AirportAnnotation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.mapType = .hybrid
        
        checkLocationServices()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationManager.startUpdatingLocation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        locationManager.stopUpdatingLocation()
    }
    
    func checkLocationServices()
    {
        if CLLocationManager.locationServicesEnabled()
        {
            setupLocationManager()
            checkLocationAuthorization()
        }
        else
        {
            // user did not enable location services for this app
        }
    }
    
    func checkLocationAuthorization()
    {
        let authorizationStatus: CLAuthorizationStatus
        
        if #available(iOS 14, *)
        {
            authorizationStatus = locationManager.authorizationStatus
        }
        else
        {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
        
        switch authorizationStatus
        {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            followUserLocation()
            locationManager.startUpdatingLocation()
            nearbyAirportsAsync()
            break
        case .denied:
            showAlert(title: "Location Access Denied", message: "This app requires access to your location to show you nearby airports. To allow access to your location, go to Settings and allow Flight Buddy to access your location.")
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            showAlert(title: "Location Access Restricted", message: "This app requires access to your location to show you nearby airports. To allow access to your location, go to Settings and allow Flight Buddy to access your location.")
            break
        case .authorizedAlways:
            break
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        checkLocationAuthorization()
    }
    
    func setupLocationManager()
    {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func followUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: 50000, longitudinalMeters: 50000)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        
        guard (annotation is AirportAnnotation) else { return nil }
        
        var annotationView = MKMarkerAnnotationView()
        annotationView.displayPriority = .required
        let identifier = "airport"
        annotationView.clusteringIdentifier = nil
        
        if let dequedAnnotation = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        {
            annotationView = dequedAnnotation
        }
        else
        {
            annotationView.canShowCallout = true
            annotationView.calloutOffset = CGPoint(x: -5.0, y: 5.0)
            annotationView.glyphImage = UIImage(systemName: "airplane.departure")
            annotationView.markerTintColor = UIColor.blue
            
            let airportButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 50.0, height: 50.0)))
            
            airportButton.setBackgroundImage(UIImage(systemName: "airplane.departure"), for: UIControl.State())
            
            annotationView.leftCalloutAccessoryView = airportButton
            
            let mapButton = UIButton (frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 50.0, height: 50.0)))
            mapButton.setBackgroundImage(UIImage(systemName: "car"), for: UIControl.State())
            annotationView.rightCalloutAccessoryView = mapButton
        }
        
        return annotationView
    }
    
    // Accessory callout
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let thisAirport = view.annotation as! AirportAnnotation
        if view.leftCalloutAccessoryView == control {
            selectedAirport = airportsModel.findAirport(withCode: thisAirport.subtitle!)
            performSegue(withIdentifier: "airportDetailSegue", sender: self)
        }
        else if view.rightCalloutAccessoryView == control
        {
            let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
            // invoke the Apple Maps application with current locations coordinate and address set as MKMapItem
            thisAirport.mapItem().openInMaps(launchOptions: launchOptions)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination_VC = segue.destination as! AirportDetailViewController
        destination_VC.selectedAirport = selectedAirport
    }
    
    func nearbyAirportsAsync() {
        
        if let currentLocation = locationManager.location {
            airportsModel.fetchNearbyAirportsData(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude, distance: requestedDistance) { result in
                if result {
                    DispatchQueue.main.async {
                        self.addNearbyAirports()
                        self.distanceLabel.text = "Showing \(self.airportsModel.getNearbyAirports().count) airports within \(Int(self.requestedDistance)) km of you"
                        self.fitAnnotations()
                        print("Successfully retrieved nearby airports")
                    }
                } else {
                    print ("error is fetching data")
                }
            }
        }
        else
        {
            checkLocationAuthorization()
        }
    }
    
    func addNearbyAirports()
    {
        for airport in airportsModel.getNearbyAirports()
        {
            airportAnnotations.append(AirportAnnotation(airport.latitude!, longitude: airport.longitude!, title: airport.name!, subtitle: airport.airportCode!, type: ""))
        }
        
        mapView.addAnnotations(airportAnnotations)
    }
    
    func fitAnnotations()
    {
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    
    @IBAction func stepperValueChanged(_ sender: UIStepper) {
        requestedDistance = sender.value
        mapView.removeAnnotations(airportAnnotations)
        airportAnnotations.removeAll()
        airportsModel.resetNearbyAirports()
        nearbyAirportsAsync()
    }
    
    @IBAction func reCenterMap(_ sender: Any) {
        fitAnnotations()
    }
    
    func showAlert(title: String, message: String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
}
