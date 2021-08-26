//
//  Pin+Extension.swift
//  Virtual Tourist
//
//  Created by Jose Antonio Álvarez Vázquez on 5/8/21.
//

import Foundation
import CoreData
import MapKit

extension Pin: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
             return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
    
    
}
