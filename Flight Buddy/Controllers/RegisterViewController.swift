//
//  RegisterViewController.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 11/27/22.
//

import UIKit
import LocalAuthentication

class RegisterViewController: UIViewController
{
    
    let userModel = UserModel.sharedInstance
    var context = LAContext()
    let server = "Flight-Buddy.csse337.s1307273.monmouth.edu"
    
    @IBOutlet weak var profileName: UITextField!
    @IBOutlet weak var emailAddress: UITextField!
    @IBOutlet weak var password: UITextField!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
    }
    
    
    @IBAction func register(_ sender: UIButton)
    {
        if let enteredProfileName = profileName.text, let enteredEmail = emailAddress.text, let enteredPassword = password.text
        {
            Task
            {
                let (result, resultMessage) = try await userModel.registerAsync(withEmail: enteredEmail, andPassword: enteredPassword, andProfileName: enteredProfileName)
                if result
                {
                    print(resultMessage)
                    print(userModel.authenticatedUser!.uid)
                    saveToKeychain(email: enteredEmail, password: enteredPassword)
                    self.dismiss(animated: true)
                }
                else
                {
                    print(resultMessage)
                    
                    showAlert(title: "Registration Failed", message: resultMessage)
                }
            }
        }
        else
        {
            showAlert(title: "Register", message: "Please enter your credentials")
        }
    }
    
    func saveToKeychain(email: String, password: String)
    {
        context = LAContext()
        
        let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, .biometryCurrentSet, nil)
        
        // Creates query with necessary info to save login to keychain
        let query: [String : Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: email,
            kSecAttrServer as String: server,
            kSecAttrAccessControl as String: access as Any,
            kSecUseAuthenticationContext as String: context,
            kSecValueData as String: password.data(using: .utf8)!
        ]
        
        // Searches for keychain items that have the same server as Flight Buddy keychain items
        let deleteQuery: [String : Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: server
        ]
        
        // Deletes old account from keychain if there is one and saves new details
        let deleteFromKeychainStatus = SecItemDelete(deleteQuery as CFDictionary)
        
        if deleteFromKeychainStatus == errSecSuccess
        {
            print("Successfully cleared old account from keychain")
        }
        else
        {
            print(SecCopyErrorMessageString(deleteFromKeychainStatus, nil) as String? ?? "Unknown error.")
        }
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else
        {
            print(SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error.")
            return
        }
    }
    
    @IBAction func cancelRegistration(_ sender: UIButton)
    {
        self.dismiss(animated: true)
    }
    
    func showAlert(title: String, message: String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
    
}
