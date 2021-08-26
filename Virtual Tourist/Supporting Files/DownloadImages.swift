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

    static func downloadImages(urlArray: [URL], context: NSManagedObjectContext, completion: @escaping ([Photo], Error?) -> Void) {
         var photos: [Photo] = []
         DispatchQueue.global(qos: .background).async {
             for url in urlArray {
                /*let task = URLSession.shared.dataTask(with: url) { data, response, error in
                    guard let data = data else {
                        print("error conecting")
                        return
                    }
                    let photo = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: context) as! Photo
                    photo.image = data
                    photo.imageUrl = url
                    print("this is the photo = ")
                    photos.append(photo)
                }
                task.resume()*/
                
                 if let imgData = try? Data(contentsOf: url) {
                    let photo = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: context) as! Photo
                    DispatchQueue.main.async {
                        photo.image = imgData
                        photo.imageUrl = url
                        photos.append(photo)
                    }
//
                 }
             }
            completion(photos, nil)
        }

    }
}
