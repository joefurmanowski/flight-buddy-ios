//
//  AirportsModel.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 11/14/22.
//

import Foundation
import FirebaseFirestore

struct NearbyAirportsData: Codable
{
    var nearbyAirports: NearbyAirports
    
    enum CodingKeys: String, CodingKey
    {
        case nearbyAirports = "response"
    }
}

struct NearbyAirports: Codable
{
    var nearbyAirports: [NearbyAirport]
    
    enum CodingKeys: String, CodingKey
    {
        case nearbyAirports = "airports"
    }
}

struct NearbyAirport: Codable
{
    var name: String?
    var airportCode: String?
    var latitude: Double?
    var longitude: Double?
    
    enum CodingKeys: String, CodingKey
    {
        case name = "name"
        case airportCode = "icao_code"
        case latitude = "lat"
        case longitude = "lng"
    }
}

struct AirportsData: Codable
{
    var airports: [Airport]
    
    enum CodingKeys: String, CodingKey
    {
        case airports = "airports"
    }
}

struct Airport: Codable
{
    var fullName: String?
    var airportCode: String?
    var countryCode: String?
    var latitude: Double?
    var longitude: Double?
    
    enum CodingKeys: String, CodingKey
    {
        case fullName = "name"
        case airportCode = "icao_code"
        case countryCode = "country_code"
        case latitude = "lat"
        case longitude = "lng"
    }
}

class AirportsModel
{
    // AirLabs API key
    let API_KEY = "API_KEY"
    let db = Firestore.firestore()
    
    static let sharedInstance = AirportsModel()
    
    var airportsData: AirportsData?
    var nearbyAirports: NearbyAirportsData?
    
    var airports: [Airport]?
    var filteredAirports: [Airport]?
    
    let airportUpdateNotification = Notification.Name(rawValue: airportUpdateNotificationKey)
    
    var listener: ListenerRegistration?
    
    private init()
    {
        readAirportsData()
    }
    
    func readAirportsData()
    {
        if let filename = Bundle.main.path(forResource: "Airports", ofType: "json")
        {
            do
            {
                let jsonStr = try String(contentsOfFile: filename)
                let jsonData = jsonStr.data(using: .utf8)!
                
                airportsData = try JSONDecoder().decode(AirportsData.self, from: jsonData)
                
                if let data = self.airportsData?.airports
                {
                    self.airports = data.filter{$0.airportCode != nil && $0.fullName != nil && $0.longitude != nil && $0.latitude != nil && $0.countryCode != nil}
                    self.filteredAirports = self.airports
                }
            }
            catch
            {
                print("The file could not be loaded.")
                print(error)
            }
        }
    }
    
    // Retrieve airport based on given airport ICAO
    func getAirport(withCode: String) -> Airport?
    {
        var airport: Airport?
        
        if let allAirports = airports, let index = allAirports.firstIndex(where: {$0.airportCode == withCode})
        {
            airport = airportsData?.airports[index]
        }
        
        return airport
    }
    
    // Observes database for any changes to a specific airport's ratings
    func observeAirport(withCode: String)
    {
        listener = db.collection("airports").document(withCode).addSnapshotListener
        {
            documentSnapshot, error in
            guard documentSnapshot != nil else
            {
                print("Error fetching document: \(error!)")
                return
            }
            
            // send notification
            NotificationCenter.default.post(name: self.airportUpdateNotification, object: nil)
        }
    }
    
    // Stop observing database for changes
    func cancelObserver()
    {
        if let listener
        {
            listener.remove()
        }
    }
    
    func findAirport(withCode: String) -> Airport?
    {
        var airport: Airport?
        
        if let allAirports = airports, let index = allAirports.firstIndex(where: {$0.airportCode == withCode})
        {
            airport = allAirports[index]
        }
        
        return airport
    }
    
    func searchAirports(text: String)
    {
        filteredAirports = text.isEmpty ? airports : airports!.filter{
            $0.fullName!.lowercased().contains(text.lowercased()) ||
            $0.airportCode!.lowercased().contains(text.lowercased()) ||
            $0.countryCode!.lowercased().contains(text.lowercased())}
    }
    
    func fetchNearbyAirportsData(latitude: Double, longitude: Double, distance: Double, _ completionHandler: @escaping (_ status: Bool) -> ())
    {
        let requestAPI: String = "https://airlabs.co/api/v9/nearby?lat=\(latitude)&lng=\(longitude)&distance=\(distance)&api_key=\(API_KEY)"
        let requestURL: URL = URL(string: requestAPI)!
        let urlRequest: URLRequest = URLRequest(url: requestURL)
        let session = URLSession.shared
        let start = Date()
        
        let task = session.dataTask(with: urlRequest, completionHandler: {(httpData, response, error) -> Void in let httpResponse = response as? HTTPURLResponse
            
            if let httpResponse
            {
                let statusCode = httpResponse.statusCode
                
                if (statusCode == 200)
                {
                    print("HTTP response 200, file downloaded successfully.")
                    do
                    {
                        self.nearbyAirports = try JSONDecoder().decode(NearbyAirportsData.self, from: httpData!)
                        let diff = Date().timeIntervalSince(start)
                        print("Elapsed time: \(diff) seconds")
                        // now clean up the array
                        completionHandler(true)
                    }
                    catch
                    {
                        print("Error with JSON: \(error)")
                        completionHandler(false)
                    }
                }
                else
                {
                    print("HTTP error: \(statusCode)")
                    completionHandler(false)
                }
            } })
        task.resume()
    }
    
    // Provides filtered nearby airports data to controllers and ensures that none of their attributes are nil
    // Cleans nearby airport data so we can guarantee that they have all the information that we need
    func getNearbyAirports() -> [NearbyAirport]
    {
        var allNearbyAirports: [NearbyAirport] = []
        
        if let airports = nearbyAirports
        {
            allNearbyAirports = airports.nearbyAirports.nearbyAirports.filter({$0.name != nil && $0.airportCode != nil && $0.latitude != nil && $0.longitude != nil})
        }
        
        return allNearbyAirports
    }
    
    func resetNearbyAirports()
    {
        nearbyAirports?.nearbyAirports.nearbyAirports.removeAll()
    }
    
    // Checks if airport exists in DB; if not, create a document in DB
    // This is the alternative to adding thousands of airports to DB at once
    // Instead, we just add the airport to database if a user tries to access it and it does not exist yet
    func checkAirportExistsInDatabase(airportCode: String)
    {
        let docRef = db.collection("airports").document(airportCode)
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                print("Document data: \(dataDescription)")
                // Document already exists in database -- do nothing else
            } else {
                print("Document does not exist - adding it to the database")
                // Set default attributes (stars and ratings) -- allows us to modify them later
                docRef.setData(["stars":0, "ratings":0])
            }
        }
    }
    
    // Gets rating as a value (e.g., 4.5 stars) for a specific airport
    func getOverallRating(forAirportCode: String, completion: @escaping (_ rating: String?) -> Void)
    {
        let docRef = db.collection("airports").document(forAirportCode)
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let stars = document.get("stars") as! Double
                let ratings = document.get("ratings") as! Double
                let zero = Double(0)
                if (ratings != zero)
                {
                    let overallRating = String(format: "%.2f", stars/ratings)
                    completion(overallRating)
                }
                else
                {
                    completion(nil)
                }
            }
            else
            {
                if let error = error
                {
                    print(error)
                }
                completion(nil)
            }
        }
    }
    
    // Gets number of ratings for a specific airport
    func getAirportRatings(forAirportCode: String, completion: @escaping (_ ratings: Int?) -> Void)
    {
        let docRef = db.collection("airports").document(forAirportCode)
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let ratings = document.get("ratings") as! Int
                if (ratings != 0)
                {
                    completion(ratings)
                }
                else
                {
                    completion(nil)
                }
            }
            else
            {
                if let error = error
                {
                    print(error)
                }
                completion(nil)
            }
        }
    }
    
    // Gets number of stars for a specific airport
    func getAirportStars(forAirportCode: String, completion: @escaping (_ stars: Int?) -> Void)
    {
        let docRef = db.collection("airports").document(forAirportCode)
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let stars = document.get("stars") as! Int
                completion(stars)
            }
            else
            {
                if let error = error
                {
                    print(error)
                }
                completion(nil)
            }
        }
    }
    
    // Check if user already rated a specific airport
    func checkAlreadyRated(withUid: String, airportCode: String, alreadyRated: @escaping (Bool) -> ())
    {
        let docRef = db.collection("airports").document(airportCode).collection("userRatings").document(withUid)
        docRef.getDocument
        {
            (document, error) in
            if let document = document, document.exists
            {
                print("User already rated this airport")
                alreadyRated(true)
            }
            else // User did not already rate this airport
            {
                alreadyRated(false)
            }
        }
    }
    
    func rateAirport(withUid: String, airportCode: String, stars: Int, alreadyRated: @escaping (Bool) -> ())
    {
        // Check if user already rated this airport
        let docRef = db.collection("airports").document(airportCode).collection("userRatings").document(withUid)
        docRef.getDocument
        {
            (document, error) in
            if let document = document, document.exists {
                let currentStars = document.get("stars") as! Int
                
                let airportDocRef = self.db.collection("airports").document(airportCode)
                
                // Update user's own rating
                airportDocRef.updateData([
                    "stars": FieldValue.increment(Int64(stars - currentStars))
                ])
                
                // Update airport's star count
                docRef.updateData([
                    "stars": stars
                ])
                
                print("User already rated this airport")
                alreadyRated(true)
            }
            else // User did not already rate this airport
            {
                // Set data for the user's own rating to the number of stars they gave
                docRef.setData(["stars":stars])
                
                // Update airport rating count and star count
                let airportDocRef = self.db.collection("airports").document(airportCode)
                airportDocRef.updateData([
                    "ratings": FieldValue.increment(Int64(1)),
                    "stars": FieldValue.increment(Int64(stars))
                ])
                
                alreadyRated(false)
            }
        }
    }
    
    func unRateAirport(withUid: String, airportCode: String, completion: @escaping (Bool) -> ())
    {
        // Check if user already rated this airport
        let docRef = db.collection("airports").document(airportCode).collection("userRatings").document(withUid)
        docRef.getDocument
        {
            (document, error) in
            if let document = document, document.exists
            {
                let currentStars = document.get("stars") as! Int
                
                // Remove user's rating from the airport's ratings
                let airportDocRef = self.db.collection("airports").document(airportCode)
                airportDocRef.updateData([
                    "ratings": FieldValue.increment(Int64(-1)),
                    "stars": FieldValue.increment(Int64(-currentStars))
                ])
                
                // Delete record of user rating
                docRef.delete()
                
                print("User already rated this airport")
                completion(true)
            }
            else
            {
                print("Error")
                completion(false)
            }
        }
    }
    
    
}
