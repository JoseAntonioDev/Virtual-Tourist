//
//  Photo+Extensions.swift
//  Virtual Tourist
//
//  Created by Jose Antonio Álvarez Vázquez on 5/8/21.
//

import Foundation
import CoreData

extension Photo {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
