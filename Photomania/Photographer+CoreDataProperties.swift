//
//  Photographer+CoreDataProperties.swift
//  Photomania
//
//

import CoreData

extension Photographer {
    @NSManaged var name: String
    @NSManaged var photos: NSSet
}