//
//  AirportDetailViewController.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 12/1/22.
//

import UIKit
import MapKit

class AirportDetailViewController: UIViewController, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var selectedAirport: Airport?
    var selectedComment: Comment?
    let airportsModel = AirportsModel.sharedInstance
    let commentsModel = CommentsModel.sharedInstance
    let userModel = UserModel.sharedInstance
    
    let commentNotification = Notification.Name(rawValue: commentNotificationKey)
    let airportUpdateNotification = Notification.Name(rawValue: airportUpdateNotificationKey)
    
    @IBOutlet weak var ratingStars: UILabel!
    @IBOutlet weak var ratingSlider: UISlider!
    @IBOutlet weak var overallRating: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var numRatings: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var unrate: UIButton!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // So user knows which airport they selected
        self.title = selectedAirport?.fullName
        
        // Set map attributes
        mapView.delegate = self
        mapView.mapType = .satellite
        
        // We control the comments table view
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        addAirport()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        // Add airport to database if it does not exist already
        airportsModel.checkAirportExistsInDatabase(airportCode: selectedAirport!.airportCode!)
        
        // Get stars and ratings info
        loadOverallRating()
        loadRatingCount()
        
        // Show un-rate button if user comes back to airport detail
        checkAlreadyRated()
        
        // Fit airport to view
        fitAnnotations()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        createObservers()
        commentsModel.observeComments(forAirport: selectedAirport!.airportCode!)
        airportsModel.observeAirport(withCode: selectedAirport!.airportCode!)
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        commentsModel.cancelObserver()
        airportsModel.cancelObserver()
        NotificationCenter.default.removeObserver(self)
    }
    
    func createObservers()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(refreshTable(notification:)), name: commentNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshRating(notification:)), name: airportUpdateNotification, object: nil)
    }
    
    @objc
    func refreshTable(notification: NSNotification)
    {
        self.tableView.reloadData()
    }
    
    @objc
    func refreshRating(notification: NSNotification)
    {
        loadOverallRating()
        loadRatingCount()
    }
    
    func loadOverallRating()
    {
        airportsModel.getOverallRating(forAirportCode: selectedAirport!.airportCode!)
        {
            (rating) in
            if let rating = rating
            {
                self.overallRating.text = "\(rating) ⭐️"
            }
            else
            {
                self.overallRating.text = "No ratings yet"
            }
        }
    }
    
    func loadRatingCount()
    {
        airportsModel.getAirportRatings(forAirportCode: selectedAirport!.airportCode!)
        {
            (ratings) in
            if let ratings = ratings
            {
                self.numRatings.text = "based on \(ratings) ratings"
            }
            else
            {
                self.numRatings.text = "Be the first to rate this airport!"
            }
        }
    }
    
    func checkAlreadyRated()
    {
        airportsModel.checkAlreadyRated(withUid: userModel.currentUser!.uid, airportCode: selectedAirport!.airportCode!) {
            (alreadyRated) in
            self.unrate.isHidden = (!alreadyRated) ? true : false
        }
    }
    
    func addAirport()
    {
        let airportAnnotation = AirportAnnotation(selectedAirport!.latitude!, longitude: selectedAirport!.longitude!, title: "\(selectedAirport!.fullName!)", subtitle: selectedAirport!.airportCode!, type: "")
        mapView.addAnnotation(airportAnnotation)
    }
    
    func fitAnnotations()
    {
        mapView.showAnnotations(mapView.annotations, animated: true)
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
        }
        
        return annotationView
    }
    
    @IBAction func rate(_ sender: UIButton) {
        airportsModel.rateAirport(withUid: userModel.currentUser!.uid, airportCode: selectedAirport!.airportCode!, stars: Int(ratingSlider.value))
        {
            (alreadyRated) in
            if !alreadyRated
            {
                self.showAlert(title: "Thanks!", message: "Your rating was successfully sent to Flight Buddy.")
                self.unrate.isHidden = false
            }
            else
            {
                self.showAlert(title: "Thanks!", message: "Your rating was successfully updated.")
            }
        }
    }
    
    func setRatingStars(_ rating: Int)
    {
        ratingStars.text = (rating == 0) ? " " : String(repeating: "⭐️", count: rating)
    }
    
    @IBAction func setRating(_ sender: UISlider) {
        let roundedUp = ratingSlider.value.rounded(.up)
        sender.setValue(roundedUp, animated: false)
        setRatingStars(Int(roundedUp))
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return commentsModel.comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! CommentTableViewCell
        
        let thisComment = commentsModel.comments[indexPath.row]
        
        cell.profileName.text = commentsModel.comments[indexPath.row].postedBy
        cell.comment.text = commentsModel.comments[indexPath.row].comment
        cell.postedDateTime.text = commentsModel.comments[indexPath.row].postedDateTime
        
        cell.backgroundColor = (indexPath.row % 2 == 0) ? .systemGray4 : .white
        
        cell.accessoryType = (thisComment.photo == nil) ? .none : .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        // Make sure we only segue to comment detail if the cell has an attached photo
        if self.tableView.cellForRow(at: indexPath)?.accessoryType == .disclosureIndicator
        {
            selectedComment = commentsModel.comments[self.tableView.indexPathForSelectedRow!.row]
            performSegue(withIdentifier: "commentDetailSegue", sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        // Row is only editable if user posted the comment
        let thisComment = commentsModel.comments[indexPath.row]
        
        return thisComment.postedByUid == userModel.currentUser?.uid ? true : false
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let thisComment = commentsModel.comments[indexPath.row]
        let deleteSwipeAction = UIContextualAction(style: .destructive, title: "Delete") {_,_,_  in
            
            let alert = UIAlertController(title: "Confirmation", message: "Are you sure you would like to delete your comment? It will not be able to be recovered.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                self.commentsModel.deleteComment(forAirport: self.selectedAirport!.airportCode!, withIndex: indexPath.row, comment: thisComment)
                self.tableView.deleteRows(at: [indexPath], with: .left)
            }))
            self.present(alert, animated: true, completion: nil)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteSwipeAction])
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        (commentsModel.comments.count == 0) ? "No comments yet" : "Comments"
    }
    
    @IBAction func newComment(_ sender: UIBarButtonItem)
    {
        performSegue(withIdentifier: "newCommentSegue", sender: self)
    }
    
    
    @IBAction func removeRating(_ sender: UIButton)
    {
        airportsModel.unRateAirport(withUid: userModel.currentUser!.uid, airportCode: selectedAirport!.airportCode!)
        {
            (result) in
            if result
            {
                self.showAlert(title: "Success", message: "Your rating was successfully removed.")
                self.unrate.isHidden = true
            }
            else
            {
                self.showAlert(title: "Error", message: "An error occurred when trying to remove your rating.")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier
        {
        case "newCommentSegue":
            let destination_VC = segue.destination as! NewCommentViewController
            destination_VC.selectedAirport = selectedAirport
        case "commentDetailSegue":
            let destination_VC = segue.destination as! CommentDetailViewController
            destination_VC.selectedComment = selectedComment
        default:
            break
        }
    }
    
    func showAlert(title: String, message: String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
    
}
