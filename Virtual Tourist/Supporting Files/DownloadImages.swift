//
//  DownloadImages.swift
//  Virtual Tourist
//
//  Created by Jose Antonio Álvarez Vázquez on 12/8/21.
//

import Foundation
import CoreData
import UIKit

class DownloadImages {

    static func downloadImage(imgUrl: URL, completion: @escaping (Data?, Error?) -> Void) {
         DispatchQueue.global(qos: .background).async {
            let request = URLRequest(url: imgUrl)
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    completion(nil, error)
                    return
                }
                completion(data, nil)
            }
            task.resume()
        }
    }
    
    static func savePhotoURL(imgPath: String, context: NSManagedObjectContext) -> Photo {
        let url = URL(string: imgPath)
        let photo = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: context) as! Photo
        photo.imageUrl = url
        return photo
    }
    
}
