//
//  FlightsTableViewController.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 11/14/22.
//

import UIKit

class FlightsTableViewController: UITableViewController {
    
    let flightsModel = FlightsModel.sharedInstance
    let userModel = UserModel.sharedInstance
    
    let searchController = UISearchController(searchResultsController: nil)
    let pullToRefreshControl = UIRefreshControl()
    
    var allFlights: [Flight]?
    var filteredFlights: [Flight]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Try to fetch flights data asynchronously
        flightsAsync()
        
        // Set up search bar
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Find a flight..."
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        // Set up table refresh
        tableView.refreshControl = pullToRefreshControl
        pullToRefreshControl.addTarget(self, action: #selector(refreshFlights), for: .valueChanged)
        pullToRefreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
    }
    
    func flightsAsync()
    {
        flightsModel.fetchFlightsData() { result in
            if result
            {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.title = "Flights (\(self.flightsModel.filteredFlights!.count))"
                    self.pullToRefreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
                    self.pullToRefreshControl.endRefreshing()
                    print("Successfully retrieved flights")
                }
            }
            else
            {
                print ("Error fetching data")
            }
        }
    }
    
    @objc
    func refreshFlights()
    {
        pullToRefreshControl.attributedTitle = NSAttributedString(string: "Refreshing...")
        flightsAsync()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let flights = flightsModel.filteredFlights
        {
            return flights.count
        }

        return 0
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "flightCell", for: indexPath) as! FlightTableViewCell
        
        let thisFlight = flightsModel.filteredFlights![indexPath.row]
        
        cell.flightNumber.text = thisFlight.flightNumber
        
        if let airline = thisFlight.airline
        {
            cell.airline.text = flightsModel.getAirlineName(withCodename: airline)
            
            if let filePath = flightsModel.getAirlineLogoFilePath(withCodename: airline)
            {
                cell.flightImage.image = UIImage(contentsOfFile: filePath)
            }
            else // fixes bug with incorrect airline logo when cell is reused
            {
                cell.flightImage.image = UIImage(systemName: "airplane")
            }
        }
        
        cell.departureAndArrival.text = "\(thisFlight.departure!) to \(thisFlight.arrival!)"
        
        cell.status.text = "Status: \(thisFlight.status!)"
        
        switch thisFlight.status
        {
        case "en-route":
            cell.flightImage.tintColor = .systemBlue
            cell.status.textColor = .systemBlue
        case "scheduled":
            cell.flightImage.tintColor = .systemYellow
            cell.status.textColor = .systemYellow
        case "landed":
            cell.flightImage.tintColor = .systemGreen
            cell.status.textColor = .systemGreen
        default:
            cell.flightImage.tintColor = .black
            cell.status.textColor = .black
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        performSegue(withIdentifier: "flightDetailSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        let destination_VC = segue.destination as! FlightDetailViewController
        let flight = flightsModel.filteredFlights![tableView.indexPathForSelectedRow!.row]
        destination_VC.selectedFlight = flight
    }
    
    
    @IBAction func logOut(_ sender: UIBarButtonItem)
    {
        // Alert
        let alert = UIAlertController(title: "Confirmation", message: "Are you sure you would like to log out? You will need to log in again.", preferredStyle: .alert)
        
        // Options
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            print("Cancel button pressed")
        })
        let logOut = UIAlertAction(title: "Log Out", style: .destructive, handler: { _ in
            print("Log out button pressed")
            self.userModel.logOut()
            print("User signed out")
            self.searchController.dismiss(animated: true)
            self.dismiss(animated: true)
        })
        alert.addAction(cancel)
        alert.addAction(logOut)
        
        // Show alert
        self.present(alert, animated: true)
    }
}

extension FlightsTableViewController: UISearchResultsUpdating
{
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }

        flightsModel.searchFlights(text: text)
        
        self.tableView.reloadData()
    }
}
