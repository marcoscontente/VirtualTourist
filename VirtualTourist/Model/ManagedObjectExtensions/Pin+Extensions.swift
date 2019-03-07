//
//  Pin+Extensions.swift
//  VirtualTourist
//
//  Created by Marcos Vinicius Goncalves Contente on 26/02/19.
//  Copyright © 2019 Marcos Vinicius Goncalves Contente. All rights reserved.
//

import Foundation
import MapKit
import CoreData

@objc(Pin)
public class Pin: NSManagedObject {
    
    static let entity = "Pin"
    
    convenience init(latitude: String, longitude: String, _ context: NSManagedObjectContext) {
        if let pinEntity = NSEntityDescription.entity(forEntityName: Pin.entity, in: context) {
            self.init(entity: pinEntity, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
        } else {
            fatalError("No name")
        }
    }
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pin> {
        return NSFetchRequest<Pin>(entityName: Pin.entity)
    }
    
    @NSManaged public var latitude: String?
    @NSManaged public var longitude: String?
    @NSManaged public var photos: NSSet?
    
    @objc(addPhotosObject:)
    @NSManaged public func addToPhotos(_ value: Photo)
    
    @objc(removePhotosObject:)
    @NSManaged public func removeFromPhotos(_ value: Photo)
    
    @objc(addPhotos:)
    @NSManaged public func addToPhotos(_ values: NSSet)
    
    @objc(removePhotos:)
    @NSManaged public func removeFromPhotos(_ values: NSSet)
    
}

