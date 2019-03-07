//
//  CoreDataStack.swift
//  VirtualTourist
//
//  Created by Marcos Vinicius Goncalves Contente on 26/02/19.
//  Copyright © 2019 Marcos Vinicius Goncalves Contente. All rights reserved.
//

import Foundation
import CoreData

struct CoreDataStack {
    
    private let object: NSManagedObjectModel
    internal let storeCoordinator: NSPersistentStoreCoordinator
    private let objectURL: URL
    internal let databaseURL: URL
    internal let privateQueue: NSManagedObjectContext
    internal let childQueue: NSManagedObjectContext
    let data: NSManagedObjectContext
    
    static func shared() -> CoreDataStack {
        struct Singleton {
            static var shared = CoreDataStack(objectName: "VirtualTourist")!
        }
        return Singleton.shared
    }
    
    init?(objectName: String) {
        
        guard let objectURL = Bundle.main.url(forResource: objectName, withExtension: "momd") else {
            print("Can't find \(objectName) in the main")
            return nil
        }
        self.objectURL = objectURL
        
        guard let object = NSManagedObjectModel(contentsOf: objectURL) else {
            print("Could not create a model from \(objectURL)")
            return nil
        }
        self.object = object
        
        storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: object)
        
        privateQueue = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateQueue.persistentStoreCoordinator = storeCoordinator
        
        data = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        data.parent = privateQueue
        
        childQueue = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        childQueue.parent = childQueue
        
        let sqLite = FileManager.default
        
        guard let inDocURL = sqLite.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to reach the documents folder")
            return nil
        }
        
        databaseURL = inDocURL.appendingPathComponent("model.sqlite")
        
        let options = [
            NSInferMappingModelAutomaticallyOption: true,
            NSMigratePersistentStoresAutomaticallyOption: true
        ]
        
        do {
            try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: databaseURL, options: options as [NSObject : AnyObject]?)
        } catch {
            print("Couldn't add store at \(databaseURL)")
        }
    }
    
    func addStoreCoordinator(_ storeType: String, configuration: String?, storeURL: URL, options : [NSObject:AnyObject]?) throws {
        try storeCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: databaseURL, options: nil)
    }
    
    func fetchPin(_ predicate: NSPredicate, entityName: String, sorting: NSSortDescriptor? = nil) throws -> Pin? {
        let fetchOne = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchOne.predicate = predicate
        if let sorting = sorting {
            fetchOne.sortDescriptors = [sorting]
        }
        guard let aPin = (try data.fetch(fetchOne) as! [Pin]).first else {
            return nil
        }
        return aPin
    }
    
    func fetchAllPins(_ predicate: NSPredicate? = nil, entityName: String, sorting: NSSortDescriptor? = nil) throws -> [Pin]? {
        let fetchMany = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchMany.predicate = predicate
        if let sorting = sorting {
            fetchMany.sortDescriptors = [sorting]
        }
        guard let allPin = try data.fetch(fetchMany) as? [Pin] else {
            return nil
        }
        return allPin
    }
    
    func fetchPhotos(_ predicate: NSPredicate? = nil, entityName: String, sorting: NSSortDescriptor? = nil) throws -> [Photo]? {
        let fetchImage = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchImage.predicate = predicate
        if let sorting = sorting {
            fetchImage.sortDescriptors = [sorting]
        }
        guard let photos = try data.fetch(fetchImage) as? [Photo] else {
            return nil
        }
        return photos
    }
}

internal extension CoreDataStack  {
    
    func dropAllData() throws {
        try storeCoordinator.destroyPersistentStore(at: databaseURL, ofType:NSSQLiteStoreType , options: nil)
        try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: databaseURL, options: nil)
    }
}

extension CoreDataStack {
    
    func saveContext() throws {
        data.performAndWait() {
            
            if data.hasChanges {
                do {
                    try data.save()
                } catch {
                    print("Error when saving main context: \(error)")
                }
                
                privateQueue.perform() {
                    do {
                        try self.privateQueue.save()
                    } catch {
                        print("Error when saving persisting context: \(error)")
                    }
                }
            }
        }
    }
    
    func autoSave(_ secondsDelay : Int) {
        
        if secondsDelay > 0 {
            do {
                try saveContext()
                print("AUTOSAVING")
            } catch {
                print("Error during autosave")
            }
            
            let nsecDelay = UInt64(secondsDelay) * NSEC_PER_SEC
            let time = DispatchTime.now() + Double(Int64(nsecDelay)) / Double(NSEC_PER_SEC)
            
            DispatchQueue.main.asyncAfter(deadline: time) {
                self.autoSave(secondsDelay)
            }
        }
    }
}
