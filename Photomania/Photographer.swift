//
//  Photographer.swift
//  Photomania
//
//

import Foundation
import CoreData

class Photographer: NSManagedObject {

    class func photographer(name: String, context: NSManagedObjectContext) -> Photographer? {
        var photographer: Photographer?
        
        if !name.isEmpty {
            guard let entity = NSEntityDescription.entityForName("Photographer", inManagedObjectContext: context)
                else {return nil}
            photographer = Photographer(entity: entity, insertIntoManagedObjectContext: context)
            photographer?.name = name
        }
        return photographer
    }
}
