//
//  NewCommentViewController.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 12/1/22.
//

import UIKit
import FirebaseStorage

class NewCommentViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    let commentsModel = CommentsModel.sharedInstance
    
    let userModel = UserModel.sharedInstance
    
    var selectedAirport: Airport?
    
    @IBOutlet weak var newComment: UITextView!
    @IBOutlet weak var commentPhoto: UIImageView!
    
    let imagePicker = UIImagePickerController()
    let storageRef = Storage.storage().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
    }
    
    @IBAction func postComment(_ sender: Any)
    {
        guard let comment = newComment.text else { return  }
        
        let commentID = timeInterval()
        
        let postedDateAndTime = getLongDateTime()
        
        let postCreator = userModel.currentUser!
        
        if let attachedPhoto = commentPhoto.image
        {
            let photo = commentID
            let postedComment = Comment(commentID: commentID, comment: comment, postedBy: postCreator.profileName, postedByUid: postCreator.uid, postedDateTime: postedDateAndTime, photo: photo)
            commentsModel.postNewCommentWithPhoto(forAirport: selectedAirport!.airportCode!, comment: postedComment, photo: attachedPhoto)
        }
        else
        {
            let postedComment = Comment(commentID: commentID, comment: comment, postedBy: postCreator.profileName, postedByUid: postCreator.uid, postedDateTime: postedDateAndTime, photo: nil)
            commentsModel.postNewComment(forAirport: selectedAirport!.airportCode!, comment: postedComment)
        }
        
        // Alert
        let alert = UIAlertController(title: "Success", message: "Comment posted!", preferredStyle: .alert)
        
        // Options
        let ok = UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        })
        
        alert.addAction(ok)
        
        // Show alert
        self.present(alert, animated: true, completion: nil)
        self.navigationController?.popViewController(animated: true)
        
    }
    
    func getLongDateTime() -> String
    {
        // Create Date
        let date = Date()
        
        // Create Date Formatter
        let dateFormatter = DateFormatter()
        
        // Set Date/Time Style
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .long
        
        // Convert Date to String
        return dateFormatter.string(from: date)
    }
    
    func timeInterval() -> String
    {
        
        let tnow = Date()
        
        var ts = String(tnow.timeIntervalSince1970)
        ts = ts.replacingOccurrences(of: ".", with: "")
        return ts
    }
    
    @IBAction func attachPhoto(_ sender: UIBarButtonItem)
    {
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        let attachActionSheet = UIAlertController(title: "Attach Photo", message: "Choose a photo source for your comment's photo", preferredStyle: .actionSheet)
        
        attachActionSheet.addAction(UIAlertAction(title: "From Camera", style: .default, handler: {
            (action: UIAlertAction) in
            if UIImagePickerController.isSourceTypeAvailable(.camera)
            {
                self.imagePicker.sourceType = .camera
                
                self.present(self.imagePicker, animated: true, completion: nil)
            }
            else
            {
                print("Camera unavailable")
            }
        }))
        
        attachActionSheet.addAction(UIAlertAction(title: "From Photo Library", style: .default, handler: {
            (action:UIAlertAction) in self.imagePicker.sourceType = .photoLibrary
            
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
        
        attachActionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(attachActionSheet, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[.editedImage] as? UIImage else { return }
        
        commentPhoto.image = image
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        self.dismiss(animated: true)
        print("User cancelled image picking")
    }
    
    
    
    
    
}
