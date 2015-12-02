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
            let request = NSFetchRequest(entityName: "Photographer")
            request.predicate = NSPredicate(format: "name = %@", name)
            
            let error = NSErrorPointer()
            let matches: [AnyObject]?
            do {
                matches = try context.executeFetchRequest(request)
            } catch let error1 as NSError {
                error.memory = error1
                matches = nil
            }
            
            if matches == nil || error != nil || matches?.count > 1 {
                //handle error
            }
            else if matches?.count > 0{
                photographer = matches?.last as? Photographer
            }
            else {
                photographer = NSEntityDescription.insertNewObjectForEntityForName("Photographer", inManagedObjectContext: context) as? Photographer
                photographer?.name = name
            }
        }
        return photographer
    }

}
