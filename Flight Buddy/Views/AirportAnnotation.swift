//
//  AirportAnnotation.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 11/22/22.
//

import Foundation
import MapKit
import Contacts

class AirportAnnotation: NSObject, MKAnnotation {

    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var type: String?
    
    init (_ latitude: CLLocationDegrees, longitude: CLLocationDegrees, title: String, subtitle: String, type: String)
    {
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.title = title
        self.subtitle = subtitle
        self.type = type
    }
    
    func mapItem() -> MKMapItem
    {
        let destinationTitle = title! + " (" + subtitle! + ")"
        let addrDict = [CNPostalAddressCityKey: destinationTitle]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addrDict)
        let mapItem = MKMapItem(placemark: placemark)
        return mapItem
    }
}
