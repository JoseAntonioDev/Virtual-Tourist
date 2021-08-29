//
//  Collection Cell.swift
//  Virtual Tourist
//
//  Created by Jose Antonio Álvarez Vázquez on 23/7/21.
//

import Foundation
import UIKit

class CollectionCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var errorLabel: UILabel!
    
    public func startIndicatingActivity() {
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
           // self.imageView.image = UIImage(systemName: )
            self.errorLabel.text = ""
        }
    }

    public func stopIndicatingActivity() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
    }
}
