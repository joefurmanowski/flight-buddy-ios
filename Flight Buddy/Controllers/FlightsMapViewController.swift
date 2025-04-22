//
//  FlightsMapViewController.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 11/18/22.
//

import UIKit
import CoreLocation
import MapKit

class FlightsMapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    let flightsModel = FlightsModel.sharedInstance
    let airportsModel = AirportsModel.sharedInstance
    let locationManager = CLLocationManager()
    let refreshNotification = Notification.Name(rawValue: refreshedFlightsNotificationKey)
    
    @IBOutlet weak var mapView: MKMapView!
    
    var flightAnnotations:[FlightAnnotation] = []
    var airportAnnotations:[AirportAnnotation] = []
    var overlay: MKGeodesicPolyline = MKGeodesicPolyline()
    var selectedFlight: Flight?
    var receivedNotification = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set map attributes
        mapView.delegate = self
        mapView.mapType = .hybridFlyover
        mapView.isRotateEnabled = false
        
        // First make sure flights data actually exists
        if let _ = flightsModel.flights
        {
            addFlights()
        }
        else
        {
            flightsAsync()
        }
        
        // When this view loads we create an observer
        // When user refreshes flights data in FlightsTVC, FlightsMapVC is notified
        // So when a user returns to the map, the refreshed flights data is shown
        createObserver()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationManager.startUpdatingLocation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if receivedNotification {
            addFlights()
            receivedNotification = false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        locationManager.stopUpdatingLocation()
    }
    
    func createObserver()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(refreshMap(notification:)), name: refreshNotification, object: nil)
    }
    
    @objc
    func refreshMap(notification: NSNotification)
    {
        receivedNotification = true
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
            locationManager.startUpdatingLocation()
            followUserLocation()
            break
        case .denied:
            showAlert(title: "Location Access Denied", message: "This app requires access to your location to show flights around your location. To allow access to your location, go to Settings and allow Flight Buddy to access your location.")
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            showAlert(title: "Location Access Restricted", message: "This app requires access to your location to show flights around your location. To allow access to your location, go to Settings and allow Flight Buddy to access your location.")
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
    
    func followUserLocation()
    {
        if let location = locationManager.location?.coordinate
        {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: 50000, longitudinalMeters: 50000)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func addFlights()
    {
        // In case user refreshes flight data, removing annotations and re-adding them shows the refreshed map
        mapView.removeAnnotations(flightAnnotations)
        flightAnnotations.removeAll()
        
        // We can force unwrap
        // This method is only called if there are actually flights in array
        for flight in flightsModel.flights!
        {
            let annotation = FlightAnnotation(flight.latitude!, longitude: flight.longitude!, title: flight.flightNumber!, subtitle: "\(flight.departure!) to \(flight.arrival!)", flight: flight)
            flightAnnotations.append(annotation)
        }
        mapView.addAnnotations(flightAnnotations)
    }
    
    func flightsAsync()
    {
        flightsModel.fetchFlightsData() { result in
            if result
            {
                DispatchQueue.main.async {
                    print("Successfully retrieved flights")
                    self.addFlights()
                }
            }
            else
            {
                print ("Error fetching data")
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        
        guard (annotation is FlightAnnotation || annotation is AirportAnnotation) else { return nil }
        
        if (annotation is FlightAnnotation)
        {
            let thisAnnotation = annotation as! FlightAnnotation
            var annotationView = MKAnnotationView()
            annotationView.displayPriority = .required
            let identifier = "flight"
            annotationView.clusteringIdentifier = nil
            
            if let dequedAnnotation = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            {
                annotationView = dequedAnnotation
            }
            else
            {
                annotationView.image = UIImage(named: "Temp-35x35")
                annotationView.canShowCallout = true
                annotationView.calloutOffset = CGPoint(x: -5.0, y: 5.0)
                
                let angle = (thisAnnotation.flight.heading! * Double.pi) / 180
                annotationView.transform = CGAffineTransformRotate(mapView.transform, angle)
                
                let airlineButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 50.0, height: 50.0)))
                
                if let airline = thisAnnotation.flight.airline
                {
                    if let filePath = flightsModel.getAirlineLogoFilePath(withCodename: airline)
                    {
                        airlineButton.setBackgroundImage(UIImage(contentsOfFile: filePath), for: UIControl.State())
                    }
                    else
                    {
                        airlineButton.setBackgroundImage(UIImage(systemName: "airplane"), for: UIControl.State())
                    }
                }
                
                annotationView.leftCalloutAccessoryView = airlineButton
            }
            return annotationView
        }
        else if (annotation is AirportAnnotation)
        {
            var annotationView = MKMarkerAnnotationView()
            annotationView.displayPriority = .required
            let thisAnnotation = annotation as! AirportAnnotation
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
                
                switch thisAnnotation.type
                {
                case "departure":
                    annotationView.glyphImage = UIImage(systemName: "airplane.departure")
                    annotationView.markerTintColor = UIColor.systemRed
                case "arrival":
                    annotationView.glyphImage = UIImage(systemName: "airplane.arrival")
                    annotationView.markerTintColor = UIColor.systemGreen
                default:
                    break
                }
            }
            return annotationView
        }
        
        return nil
    }
    
    // Accessory callout
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl)
    {
        let thisFlight = view.annotation as! FlightAnnotation
        if view.leftCalloutAccessoryView == control
        {
            selectedFlight = thisFlight.flight
            performSegue(withIdentifier: "flightDetailSegue", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        let destination_VC = segue.destination as! FlightDetailViewController
        destination_VC.selectedFlight = selectedFlight
    }
    
    func showFlightPath(forFlight: Flight)
    {
        if let departureAirport = airportsModel.getAirport(withCode: forFlight.departure!),
           let arrivalAirport = airportsModel.getAirport(withCode: forFlight.arrival!)
        {
            let flight = CLLocation(latitude: forFlight.latitude!, longitude: forFlight.longitude!)
            let departure = CLLocation(latitude: departureAirport.latitude!, longitude: departureAirport.longitude!)
            let arrival = CLLocation(latitude: arrivalAirport.latitude!, longitude: arrivalAirport.longitude!)
            let coordinates = [departure.coordinate, flight.coordinate, arrival.coordinate]
            let geodesicPolyline = MKGeodesicPolyline(coordinates: coordinates, count: 3)
            overlay = geodesicPolyline
            mapView.addOverlay(overlay)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let overlay = overlay as? MKPolyline else { return MKOverlayRenderer() }
        let renderer = MKPolylineRenderer(polyline: overlay)
        renderer.lineWidth = 5.0
        renderer.alpha = 0.7
        renderer.strokeColor = UIColor.blue
        renderer.lineDashPattern = [2, 10]
        return renderer
    }
    
    @IBAction func focusUserLocation(_ sender: UIBarButtonItem) {
        checkLocationServices()
        followUserLocation()
    }
    
    func showAlert(title: String, message: String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
}
