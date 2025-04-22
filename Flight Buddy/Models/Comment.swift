//
//  Comment.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 12/1/22.
//

import Foundation
import Firebase
import FirebaseFirestore

struct Comment
{
    var ref: DocumentReference?
    var commentID: String
    var comment: String
    var postedBy: String
    var postedByUid: String
    var postedDateTime: String
    var photo: String?
    
    init(commentID: String, comment: String, postedBy: String, postedByUid: String, postedDateTime: String, photo: String?) {
        self.ref = nil
        self.commentID = commentID
        self.comment = comment
        self.postedBy = postedBy
        self.postedByUid = postedByUid
        self.postedDateTime = postedDateTime
        self.photo = photo
    }
    
    init? (snapshot: DocumentSnapshot)
    {
        if let data = snapshot.data() as? [String: AnyObject]
        {
            guard
                let commentID = data["commentID"] as? String,
                let comment = data["comment"] as? String,
                let postedBy = data["postedBy"] as? String,
                let postedByUid = data["postedByUid"] as? String,
                let postedDateTime = data["postedDateTime"] as? String
            else
            {
                return nil
            }
            
            self.ref = snapshot.reference
            self.commentID = commentID
            self.comment = comment
            self.postedBy = postedBy
            self.postedByUid = postedByUid
            self.postedDateTime = postedDateTime
            
            if let attachedPhoto = data["photo"] as? String
            {
                self.photo = attachedPhoto
            }
            else
            {
                self.photo = nil
            }
        }
        else
        {
            return nil
        }
    }
    
    func toAnyObject() -> Dictionary<String, Any>
    {
        return [
            "commentID": self.commentID,
            "comment": self.comment,
            "postedBy": self.postedBy,
            "postedByUid": self.postedByUid,
            "postedDateTime": self.postedDateTime,
            "photo": self.photo
        ]
    }
    
}
