//
//  ViewController+HideKeyboard.swift
//  Flight Buddy
//
//  Created by Joseph T. Furmanowski on 11/27/22.
//

import UIKit

extension UIViewController
{
    func hideKeyboardWhenTappedAround()
    {
        let tap: UIGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardView))
        tap.cancelsTouchesInView = true
        view.addGestureRecognizer(tap)
    }
    
    @objc
    func dismissKeyboardView()
    {
        view.endEditing(true)
    }
}
