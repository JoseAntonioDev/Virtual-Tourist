//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Jose Antonio Álvarez Vázquez on 23/7/21.
//

import Foundation

class FlickrClient {
   
    static let apiKey = "a0518a19f71fd9a86d3faca00d1c990c"
    static let secretKey = "44bab3efd70e5d0e"
    
    enum Endpoints {
        
        static let base = "https://www.flickr.com/services/rest/?method=flickr.photos.search"
        
        case getPhotos(Double, Double, Int)
        
        var stringValue: String {
            switch self {
           
            case .getPhotos(let lat, let lon, let pageNum):
                return Endpoints.base
                + "&api_key=\(FlickrClient.apiKey)"
                + "&lat=\(lat)"
                + "&lon=\(lon)"
                + "&radius=15"
                + "&per_page=10"
                + "&page=\(pageNum)"
                + "&format=json&nojsoncallback=1"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    // Random number to use in Flickr Request
    class func randomPhotos() -> Int {
        let n = Int.random(in: 1...10)
        return n
    }
    
    // This function does a request to get photos by location from Flickr
    class func getPhotosByLocation(lat: Double, lon: Double, completion: @escaping (FlickrResponse?, Error?) -> Void) {
        let url = Endpoints.getPhotos(lat, lon, randomPhotos()).url
        taskForGETRequest(url: url, responseType: FlickrResponse.self) { response, error in
            guard let response = response else {
                completion(nil, error)
                return
            }
            completion(response, nil)
        }
    }
    
    // Get an image path from Flickr's response
    class func getImgPath(photoStruct: PhotoStruct) -> String {
        let imagePath: String = "https://farm\(photoStruct.farm).staticflickr.com/\(photoStruct.server)/\(photoStruct.id)_\(photoStruct.secret).jpg"
        
        return imagePath
    }
    
}

// MARK: - Network methods
@discardableResult func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionDataTask {
    
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        guard let data = data else {
            DispatchQueue.main.async {
                completion(nil, error)
            }
            return
        }
        let decoder = JSONDecoder()
        do {
            let requestObject = try decoder.decode(responseType.self, from: data)
            DispatchQueue.main.async {
                completion(requestObject, nil)
            }
        } catch {
            do  {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
    task.resume()
    return task
}
