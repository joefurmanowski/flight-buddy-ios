//
//  User.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 11/27/22.
//

import Foundation
import Firebase
import FirebaseFirestore

struct User
{
    let ref: DocumentReference?
    let uid: String
    let profileName: String
    let email: String
    
    init (uid: String, profileName: String, email: String)
    {
        self.ref = nil
        self.uid = uid
        self.profileName = profileName
        self.email = email
    }
    
    init? (snapshot: DocumentSnapshot)
    {
        print(snapshot.data()!)
        guard
            let value = snapshot.data() as? [String: AnyObject],
            let uid = value["uid"] as? String,
            let profileName = value["profileName"] as? String,
            let email = value["email"] as? String
        else
        {
            return nil
        }
        
        self.ref = snapshot.reference
        self.uid = uid
        self.profileName = profileName
        self.email = email
    }
    
    func toAnyObject() -> Dictionary<String, String>
    {
        return [
            "uid": uid,
            "profileName": profileName,
            "email": email
        ]
    }
}
