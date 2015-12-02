//
//  Photo+Flickr.swift
//  Photomania
//
//

import CoreData

extension Photo { 
    @NSManaged var imageURL: String
    @NSManaged var title: String
    @NSManaged var subtitle: String
    @NSManaged var unique: String
    @NSManaged var whoTook: NSManagedObject

}