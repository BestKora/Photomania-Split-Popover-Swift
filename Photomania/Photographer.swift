//
//  Photographer.swift
//  Photomania
//
//

import Foundation
import CoreData

class Photographer: NSManagedObject {

    convenience init?(name: String, context: NSManagedObjectContext) {
        
        // убираем пробелы с обоих концов
        let photographerName = name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        guard !photographerName.isEmpty ,
            let entity = NSEntityDescription.entityForName("Photographer", inManagedObjectContext: context)
            else {return nil}
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        self.name = photographerName
    }
}
