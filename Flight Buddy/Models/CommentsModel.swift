//
//  CommentsModel.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 12/1/22.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseStorage

class CommentsModel
{
    static let sharedInstance = CommentsModel()
    
    let db = Firestore.firestore()
    
    let commentNotification = Notification.Name(rawValue: commentNotificationKey)
    
    var comments:[Comment] = []
    
    var listener: ListenerRegistration?
    
    // Observe comments data for a specific airport
    func observeComments(forAirport: String)
    {
        var tempComments:[Comment] = []
        listener = db.collection("airports").document(forAirport).collection("comments").addSnapshotListener
        {
            querySnapshot, error in
            guard let documents = querySnapshot?.documents else
            {
                print("Error fetching documents: \(error!)")
                return
            }
            
            tempComments.removeAll()
            
            tempComments = documents.compactMap({Comment(snapshot: $0)})
            
            self.comments.removeAll()
            self.comments = tempComments.sorted{$0.postedDateTime > $1.postedDateTime}
            
            // send notification
            NotificationCenter.default.post(name: self.commentNotification, object: nil)
        }
    }
    
    // Stop observing airport
    func cancelObserver()
    {
        if let listener
        {
            listener.remove()
        }
        
        comments.removeAll()
    }
    
    func postNewComment(forAirport: String, comment: Comment)
    {
        db.collection("airports").document(forAirport).collection("comments").document(comment.commentID).setData(comment.toAnyObject())
    }
    
    func postNewCommentWithPhoto(forAirport: String, comment: Comment, photo: UIImage)
    {
        db.collection("airports").document(forAirport).collection("comments").document(comment.commentID).setData(comment.toAnyObject())
        uploadPhoto(id: comment.commentID, photo: photo)
    }
    
    func deleteComment(forAirport: String, withIndex: Int, comment: Comment)
    {
        comments.remove(at: withIndex)
        db.collection("airports").document(forAirport).collection("comments").document(comment.commentID).delete()
        
        // Check if comment has photo
        // If it does, delete photo from storage when comment is deleted
        if let _ = comment.photo
        {
            // Delete the photo from storage
            let storageRef = Storage.storage().reference()
            let photoRef = storageRef.child(comment.commentID)
            
            photoRef.delete
            {
                error in
                if let _ = error
                {
                    print("Error deleting photo from storage")
                }
                else
                {
                    print("Photo deleted")
                }
            }
        }
    }
    
    func uploadPhoto(id: String, photo image: UIImage)
    {
        let storageRef = Storage.storage().reference()
        
        if let data = image.jpegData(compressionQuality: 0.50)
        {
            let photoID = id
            let photoRef = storageRef.child(photoID)
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpg"
            
            let _ = photoRef.putData(data, metadata: metadata)
            {
                (metadata, error) in guard let metadata = metadata else
                {
                    return
                }
                
                print(metadata.size)
                
                photoRef.downloadURL
                {
                    (url,error) in guard let downloadURL = url else
                    {
                        return
                    }
                    print(downloadURL)
                }
            }
        }
    }
    
    func timeInterval() -> String
    {
        let tnow = Date()
        var ts = String(tnow.timeIntervalSince1970)
        ts = ts.replacingOccurrences(of: ".", with: "")
        return ts
    }
}
