//
//  FlightsModel.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 11/14/22.
//

import Foundation

struct FlightsData: Codable
{
    var flights: [Flight]
    
    enum CodingKeys: String, CodingKey
    {
        case flights = "response"
    }
}

struct Flight: Codable
{
    var latitude: Double?
    var longitude: Double?
    var heading: Double?
    var altitude: Int?
    var flightNumber: String?
    var departure: String?
    var arrival: String?
    var airline: String?
    var aircraft: String?
    var status: String?
    
    enum CodingKeys: String, CodingKey
    {
        case latitude = "lat"
        case longitude = "lng"
        case heading = "dir"
        case altitude = "alt"
        case flightNumber = "flight_icao"
        case departure = "dep_icao"
        case arrival = "arr_icao"
        case airline = "airline_icao"
        case aircraft = "aircraft_icao"
        case status = "status"
    }
}

struct AirlinesData: Codable
{
    var airlines: [Airline]
    
    enum CodingKeys: String, CodingKey
    {
        case airlines = "airlines"
    }
}

struct Airline: Codable
{
    var name: String?
    var codename: String?
    
    enum CodingKeys: String, CodingKey
    {
        case name = "name"
        case codename = "icao_code"
    }
}

class FlightsModel
{
    // AirLabs API key
    let API_KEY = "API_KEY"
    
    var flightsData: FlightsData?
    var airlinesData: AirlinesData?
    
    var flights: [Flight]?
    var filteredFlights: [Flight]?
    
    let refreshNotification = Notification.Name(refreshedFlightsNotificationKey)
    
    static let sharedInstance = FlightsModel()
    
    private init()
    {
        readAirlinesData()
    }
    
    // Gets global flights from the API
    func fetchFlightsData(_ completionHandler: @escaping (_ status: Bool) -> ())
    {
        let requestAPI: String = "https://airlabs.co/api/v9/flights?fields=lat,lng,alt,flight_icao,dep_icao,arr_icao,airline_icao,aircraft_icao,status&api_key=\(API_KEY)"
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
                        self.flightsData = try JSONDecoder().decode(FlightsData.self, from: httpData!)
                        let diff = Date().timeIntervalSince(start)
                        print("Elapsed time: \(diff) seconds")
                        // now clean up the array
                        if let data = self.flightsData?.flights
                        {
                            self.flights = data.filter({$0.flightNumber != nil && $0.departure != nil && $0.arrival != nil && $0.aircraft != nil && $0.altitude != nil && $0.latitude != nil && $0.longitude != nil && $0.airline != nil && $0.heading != nil && self.getAirlineName(withCodename: $0.airline!) != nil})
                            self.filteredFlights = self.flights
                            // send notification to map which relies on this flight data
                            NotificationCenter.default.post(name: self.refreshNotification, object: nil)
                        }
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
            }})
        
        task.resume()
    }
    
    func readAirlinesData()
    {
        if let filename = Bundle.main.path(forResource: "Airlines", ofType: "json")
        {
            do
            {
                let jsonStr = try String(contentsOfFile: filename)
                let jsonData = jsonStr.data(using: .utf8)!
                airlinesData = try JSONDecoder().decode(AirlinesData.self, from: jsonData)
            }
            catch
            {
                print("The file could not be loaded.")
                print(error)
            }
        }
    }
    
    // Provides airline name based on given airline ICAO
    func getAirlineName (withCodename: String) -> String?
    {
        var name: String?
        
        if let _ = airlinesData, let index = airlinesData!.airlines.firstIndex(where: {$0.codename == withCodename})
        {
            if let airline = airlinesData?.airlines[index].name
            {
                name = airline
            }
        }
        
        return name
    }
    
    // Provides logo file path of an airline's logo given its ICAO
    func getAirlineLogoFilePath(withCodename: String) -> String?
    {
        var filePath: String?
        
        if let _ = airlinesData, let _ = airlinesData!.airlines.firstIndex(where: {$0.codename == withCodename})
        {
            if let logoFilePath = Bundle.main.path (forResource: "/logos/" + withCodename + ".png", ofType: "") {
                filePath = logoFilePath
            }
        }
        
        return filePath
    }
    
    func searchFlights(text: String)
    {
        filteredFlights = text.isEmpty ? flights : flights!.filter{
            $0.flightNumber!.lowercased().contains(text.lowercased()) ||
            $0.departure!.lowercased().contains(text.lowercased()) ||
            $0.arrival!.lowercased().contains(text.lowercased()) ||
            $0.airline!.lowercased().contains(text.lowercased())
        }
    }
    
}
