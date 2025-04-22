//
//  FlightAnnotation.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 11/18/22.
//

import Foundation
import MapKit
import UIKit

class FlightAnnotation: NSObject, MKAnnotation {

    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var flight: Flight
    
    init (_ latitude: CLLocationDegrees, longitude: CLLocationDegrees, title: String, subtitle: String, flight: Flight)
    {
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.title = title
        self.subtitle = subtitle
        self.flight = flight
    }
}
