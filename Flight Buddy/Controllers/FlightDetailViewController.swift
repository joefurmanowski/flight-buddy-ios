//
//  FlightDetailViewController.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 11/18/22.
//

import UIKit
import MapKit

class FlightDetailViewController: UIViewController, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    let flightsModel = FlightsModel.sharedInstance
    let airportsModel = AirportsModel.sharedInstance
    var selectedFlight: Flight?
    var selectedAirport: Airport?
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    var flightAnnotations:[FlightAnnotation] = []
    var airportAnnotations:[AirportAnnotation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Map attributes
        mapView.delegate = self
        mapView.mapType = .hybridFlyover
        mapView.isRotateEnabled = false
        
        // We are delegate and data source for the flight details table view
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        // Add single flight to the map
        addFlight()
        
        // Add departure and arrival airports to map
        addAirports()
        
        // Fit all annotations to view
        fitAnnotations()
        
        // Draw flight path
        showFlightPath()
        
        // Indicate to user which flight they're looking at
        self.title = selectedFlight?.flightNumber
    }
    
    func addFlight()
    {
        let annotation = FlightAnnotation(selectedFlight!.latitude!, longitude: selectedFlight!.longitude!, title: selectedFlight!.flightNumber!, subtitle: "\(selectedFlight!.departure!) to \(selectedFlight!.arrival!)", flight: selectedFlight!)
        mapView.addAnnotation(annotation)
    }
    
    func addAirports()
    {
        if let departureAirport = airportsModel.getAirport(withCode: selectedFlight!.departure!),
           let arrivalAirport = airportsModel.getAirport(withCode: selectedFlight!.arrival!)
        {
            let departureAnnotation = AirportAnnotation(departureAirport.latitude!, longitude: departureAirport.longitude!, title: departureAirport.fullName!, subtitle: departureAirport.airportCode!, type: "departure")
            let arrivalAnnotation = AirportAnnotation(arrivalAirport.latitude!, longitude: arrivalAirport.longitude!, title: arrivalAirport.fullName!, subtitle: arrivalAirport.airportCode!, type: "arrival")
            airportAnnotations.append(departureAnnotation)
            airportAnnotations.append(arrivalAnnotation)
            mapView.addAnnotation(departureAnnotation)
            mapView.addAnnotation(arrivalAnnotation)
        }
    }
    
    // Draw flight path using MKGeodesicPolyline
    func showFlightPath()
    {
        if let departureAirport = airportsModel.getAirport(withCode: selectedFlight!.departure!),
           let arrivalAirport = airportsModel.getAirport(withCode: selectedFlight!.arrival!)
        {
            let flight = CLLocation(latitude: selectedFlight!.latitude!, longitude: selectedFlight!.longitude!)
            let departure = CLLocation(latitude: departureAirport.latitude!, longitude: departureAirport.longitude!)
            let arrival = CLLocation(latitude: arrivalAirport.latitude!, longitude: arrivalAirport.longitude!)
            let coordinates = [departure.coordinate, flight.coordinate, arrival.coordinate]
            let geodesicPolyline = MKGeodesicPolyline(coordinates: coordinates, count: 3)
            mapView.addOverlay(geodesicPolyline)
        }
    }
    
    func fitAnnotations()
    {
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    func addFlights()
    {
        for flight in flightsModel.flights!
        {
            let annotation = FlightAnnotation(flight.latitude!, longitude: flight.longitude!, title: flight.flightNumber!, subtitle: String(flight.altitude!), flight: flight)
            flightAnnotations.append(annotation)
        }
        
        mapView.addAnnotations(flightAnnotations)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let overlay = overlay as? MKPolyline else { return MKOverlayRenderer() }
        let renderer = MKPolylineRenderer(polyline: overlay)
        renderer.lineWidth = 5.0
        renderer.alpha = 0.7
        renderer.strokeColor = UIColor.green
        renderer.lineDashPattern = [2, 10]
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        
        guard (annotation is FlightAnnotation || annotation is AirportAnnotation) else { return nil }
        
        
        if annotation is FlightAnnotation
        {
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
                annotationView.canShowCallout = false
                annotationView.calloutOffset = CGPoint(x: -5.0, y: 5.0)
                
                let angle = (selectedFlight!.heading! * Double.pi) / 180
                annotationView.transform = CGAffineTransformRotate(mapView.transform, angle)
                
                let airlineButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 50.0, height: 50.0)))
                
                if let airline = selectedFlight!.airline
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
        else if annotation is AirportAnnotation
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
                
                let airportButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 50.0, height: 50.0)))
                
                annotationView.leftCalloutAccessoryView = airportButton
                
                switch thisAnnotation.type
                {
                case "departure":
                    annotationView.glyphImage = UIImage(systemName: "airplane.departure")
                    annotationView.markerTintColor = UIColor.systemRed
                    airportButton.setBackgroundImage(UIImage(systemName: "airplane.departure"), for: UIControl.State())
                case "arrival":
                    annotationView.glyphImage = UIImage(systemName: "airplane.arrival")
                    annotationView.markerTintColor = UIColor.systemGreen
                    airportButton.setBackgroundImage(UIImage(systemName: "airplane.arrival"), for: UIControl.State())
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
        let thisAirport = view.annotation as! AirportAnnotation
        if view.leftCalloutAccessoryView == control
        {
            selectedAirport = airportsModel.findAirport(withCode: thisAirport.subtitle!)
            performSegue(withIdentifier: "airportDetailSegue", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        let destination_VC = segue.destination as! AirportDetailViewController
        destination_VC.selectedAirport = selectedAirport
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "flightInfoCell", for: indexPath)
        
        if (indexPath.row % 2 == 0) {
            cell.backgroundColor = .systemGray4
        } else {
            cell.backgroundColor = .white
        }
        switch indexPath.row
        {
        case 0:
            cell.textLabel?.text = "Flight Number"
            cell.detailTextLabel?.text = "\(selectedFlight!.flightNumber!)"
        case 1:
            let airline = flightsModel.getAirlineName(withCodename: selectedFlight!.airline!)
            cell.textLabel?.text = "Airline"
            cell.detailTextLabel?.text = "\(airline!) (ICAO: \(selectedFlight!.airline!))"
        case 2:
            cell.textLabel?.text = "Altitude"
            cell.detailTextLabel?.text = "\(selectedFlight!.altitude!)m"
        case 3:
            cell.textLabel?.text = "Departure"
            cell.detailTextLabel?.text = "\(selectedFlight!.departure!)"
            cell.accessoryType = .disclosureIndicator
        case 4:
            cell.textLabel?.text = "Arrival"
            cell.detailTextLabel?.text = "\(selectedFlight!.arrival!)"
            cell.accessoryType = .disclosureIndicator
        case 5:
            cell.textLabel?.text = "Status"
            cell.detailTextLabel?.text = "\(selectedFlight!.status!)"
        case 6:
            cell.textLabel?.text = "Latitude"
            cell.detailTextLabel?.text = "\(selectedFlight!.latitude!)°"
        case 7:
            cell.textLabel?.text = "Longitude"
            cell.detailTextLabel?.text = "\(selectedFlight!.longitude!)°"
        case 8:
            cell.textLabel?.text = "Heading"
            cell.detailTextLabel?.text = "\(selectedFlight!.heading!)°"
        case 9:
            cell.textLabel?.text = "Aircraft"
            cell.detailTextLabel?.text = "\(selectedFlight!.aircraft!)"
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        // Only allow segue when user taps cell with departure or arrival airport
        if let thisCell = self.tableView.cellForRow(at: indexPath), (indexPath.row == 3 || indexPath.row == 4)
        {
            selectedAirport = airportsModel.findAirport(withCode: thisCell.detailTextLabel!.text!)
            performSegue(withIdentifier: "airportDetailSegue", sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Flight Details"
    }
    
    @IBAction func centerOnFlight(_ sender: UIBarButtonItem)
    {
        fitAnnotations()
    }
    
    
}
