//
//  ActivityIndicator.swift
//  Virtual Tourist
//
//  Created by Jose Antonio Álvarez Vázquez on 25/8/21.
//

import Foundation

// MARK: - Acitivity Indicator
extension PhotoAlbumVC {
    public func startIndicatingActivity() {
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
            self.view.isUserInteractionEnabled = false
            self.emptyText.text = "Downloading 😎"
            
        }
    }

    public func stopIndicatingActivity() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.view.isUserInteractionEnabled = true
        }
    }
}
