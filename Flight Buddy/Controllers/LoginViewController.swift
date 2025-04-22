//
//  LoginViewController.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 11/13/22.
//

import UIKit
import LocalAuthentication

class LoginViewController: UIViewController
{
    let userModel = UserModel.sharedInstance
    var context = LAContext()
    let server = "Flight-Buddy.csse337.s1307273.monmouth.edu"
    
    @IBOutlet weak var emailAddress: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var biometricLogin: UIButton!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        emailAddress.text = ""
        password.text = ""
    }

    @IBAction func logIn(_ sender: UIButton)
    {
        performLogIn()
    }
    
    
    @IBAction func logInWithFaceID(_ sender: UIButton)
    {
        context = LAContext()
        var error: NSError?
        
        // Verify that hardware supports biometric authentication
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else
        {
            showAlert(title: "Error", message: error?.localizedDescription ?? "Can't evaluate policy")
            return
        }
        
        Task {
            do {
                try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Log in to your account using biometrics")
                retrieveLoginFromKeychain(server: server)
            }
            catch let error
            {
                print(error.localizedDescription)
            }
        }
    }
    
    func performLogIn()
    {
        Task
        {
            if let enteredEmail = emailAddress.text, let enteredPassword = password.text
            {
                let (result, resultMessage) = try await userModel.logInAsync(withEmail: enteredEmail, andPassword: enteredPassword)
                if result
                {
                    performSegue(withIdentifier: "mainSegue", sender: self)
                }
                else
                {
                    showAlert(title: "Log In Failed", message: resultMessage)
                }
            }
            else
            {
                showAlert(title: "Log In Failed", message: "Please enter your credentials")
            }
        }
    }
    
    func retrieveLoginFromKeychain(server: String)
    {
        context = LAContext()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: server,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecUseAuthenticationContext as String: context,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else
        {
            print(SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error.")
            return
        }
        
        guard let keychainItem = item as? [String: Any],
              let passwordData = keychainItem[kSecValueData as String] as? Data,
              let password = String(data: passwordData, encoding: String.Encoding.utf8),
              let email = keychainItem[kSecAttrAccount as String] as? String
        else {
            print(SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error.")
            return
        }
        
        self.emailAddress.text = email
        self.password.text = password
    }
    
    func showAlert(title: String, message: String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
    
    
}

