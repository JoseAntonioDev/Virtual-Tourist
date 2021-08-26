//
//  Errors.swift
//  Virtual Tourist
//
//  Created by Jose Antonio Álvarez Vázquez on 25/8/21.
//

import Foundation
import UIKit

// List of errors that could happen during running the app
public enum Errors: Error {
    case flickrServer

}

// Description of each
extension Errors: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .flickrServer: return "Error from the server, please check your connection & try again."

        }
    }
}

// Function that shows them
func showError(message: String, actualVC: UIViewController) {
    let alertVC = UIAlertController(title: "An Error Has Occurred", message: message, preferredStyle: .alert)
    alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    actualVC.present(alertVC, animated: true, completion: nil)
}
