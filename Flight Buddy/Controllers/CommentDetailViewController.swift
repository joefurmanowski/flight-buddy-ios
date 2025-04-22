//
//  CommentDetailViewController.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 12/4/22.
//

import UIKit
import FirebaseStorage

class CommentDetailViewController: UIViewController, UIScrollViewDelegate {
    
    let commentsModel = CommentsModel.sharedInstance
    let storageRef = Storage.storage().reference()
    var selectedComment: Comment?
    let largePhotoView = UIImageView()
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "\(selectedComment!.postedBy)'s Photo"
        // Create a reference to the file you want to download
        let photoRef = storageRef.child("/\(selectedComment!.photo!)")
        
        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        photoRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                print(error)
                // Alert
                let alert = UIAlertController(title: "Error", message: "Sorry, the selected photo could not be found.", preferredStyle: .alert)
                
                // Options
                
                let ok = UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self.navigationController?.popViewController(animated: true)
                })
                
                alert.addAction(ok)
                
                // Show alert
                self.present(alert, animated: true, completion: nil)
            } else {
                self.largePhotoView.image = UIImage(data: data!)
                self.largePhotoView.sizeToFit()
                self.scrollView.addSubview(self.largePhotoView)
                self.scrollView.contentSize = self.largePhotoView.bounds.size
                self.scrollView.minimumZoomScale = 0.01
                self.scrollView.maximumZoomScale = 2.0
                self.scrollView.delegate = self
            }
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return largePhotoView
    }
    
    
    
}
