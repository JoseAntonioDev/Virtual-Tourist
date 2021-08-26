//
//  FlickrData.swift
//  Virtual Tourist
//
//  Created by Jose Antonio Álvarez Vázquez on 28/7/21.
//

import Foundation

struct Photos: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: Int
    let photo: [PhotoStruct]
}

struct PhotoStruct: Codable {
    let id: String
    let server: String
    let farm: Int
    let secret: String
}
