//
//  FlickrResponse.swift
//  Virtual Tourist
//
//  Created by Jose Antonio Álvarez Vázquez on 28/7/21.
//

import Foundation

struct FlickrResponse: Codable {
    let photos: Photos
    let stat: String
}
