//
//  AirportsTableViewController.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 11/30/22.
//

import UIKit
import FlagKit

class AirportsTableViewController: UITableViewController {
    
    let airportsModel = AirportsModel.sharedInstance
    let searchController = UISearchController(searchResultsController: nil)
    
    var allAirports: [Airport]?
    var filteredAirports: [Airport]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up search bar
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Find an airport..."
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        if let airports = airportsModel.filteredAirports
        {
            self.title = "Airports (\(airports.count))"
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let airports = airportsModel.filteredAirports
        {
            return airports.count
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "airportCell", for: indexPath) as! AirportTableViewCell
        
        let thisAirport = airportsModel.filteredAirports![indexPath.row]

        if let flag = Flag(countryCode: thisAirport.countryCode!)
        {
            cell.flag.image = flag.image(style: .roundedRect)
        }
        else
        {
            cell.flag.image = UIImage(systemName: "flag.slash.fill")
        }

        cell.airportName.text = thisAirport.fullName!
        cell.airportDetails.text = "\(thisAirport.airportCode!) (\(thisAirport.countryCode!))"
        
        return cell
        
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "airportDetailSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination_VC = segue.destination as! AirportDetailViewController
        destination_VC.selectedAirport = airportsModel.filteredAirports![self.tableView.indexPathForSelectedRow!.row]
    }
    
}

extension AirportsTableViewController: UISearchResultsUpdating
{
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        
        airportsModel.searchAirports(text: text)
                
        self.tableView.reloadData()
    }
}
