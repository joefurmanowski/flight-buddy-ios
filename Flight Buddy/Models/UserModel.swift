//
//  UserModel.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 11/14/22.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class UserModel
{
    static let sharedInstance = UserModel()
    let db = Firestore.firestore()
    var authenticatedUser: AuthenticatedUser?
    var currentUser: User?
    
    private init() { }
    
    func logInAsync(withEmail email: String, andPassword pw: String) async throws -> (Bool, String)
    {
        do
        {
            let authData = try await Auth.auth().signIn(withEmail: email, password: pw)
            authenticatedUser = AuthenticatedUser(uid: authData.user.uid, email: authData.user.email!)
            try await getLoggedInUser()
            return (true, "Log in successful")
        }
        catch
        {
            let err = error
            return (false, err.localizedDescription)
        }
    }
    
    func logOut()
    {
        do
        {
            try Auth.auth().signOut()
        }
        catch let logOutError as NSError
        {
            print("Error logging out: %@", logOutError)
        }
    }
    
    func registerAsync(withEmail email: String, andPassword pw: String, andProfileName name: String) async throws -> (Bool, String)
    {
        do
        {
            let userCreationResponse = try await Auth.auth().createUser(withEmail: email, password: pw)
            authenticatedUser = AuthenticatedUser(uid: userCreationResponse.user.uid, email: userCreationResponse.user.email!)
            newRegisteredUser(withUid: authenticatedUser!.uid, andProfileName: name, andEmail: email)
            return (true, "Successfully registered user")
        }
        catch
        {
            let err = error
            return (false, err.localizedDescription)
        }
    }
    
    func newRegisteredUser(withUid uid: String, andProfileName name: String, andEmail email: String)
    {
        let user = User(uid: uid, profileName: name, email: email)
        db.collection("users").document(user.uid).setData(user.toAnyObject())
    }
    
    func getLoggedInUser() async throws
    {
        do
        {
            if let uid = authenticatedUser?.uid
            {
                let userData = try await db.collection("users").document(uid).getDocument()
                currentUser = User(snapshot: userData)
            }
        }
        catch
        {
            print("Cannot retrieve user data")
        }
    }
}
