import Foundation
import UIKit
import CoreData

//
//  CDTVConroller.swift
//  RDP
//
//  Created by Renato Deris Prado on 31/01/15.
//  Copyright (c) 2015 RDP. All rights reserved.
//
// This class is similar to the Stanford CS193p CDTVController, but rewritten in Swift. It mostly just copies the code from NSFetchedResultsController's documentation page into a subclass of UITableViewController.
//
// The only UITableViewDataSource method you'll HAVE to implement is tableView:cellForRowAtIndexPath:.
// And you can use the NSFetchedResultsController method objectAtIndexPath: to do it.
//
// Remember that once you create an NSFetchedResultsController, you CANNOT modify its propertys.
// If you want new fetch parameters (predicate, sorting, etc.),
//  create a NEW NSFetchedResultsController and set this class's fetchedResultsController @property again.
//

// This class fetches nothing if NSFetchedResultsController is not set.

class CoreDataTableViewController : UITableViewController, NSFetchedResultsControllerDelegate {
    
    let debug = true
    
    // The controller (this class fetches nothing if this is not set).
    var fetchedResultsController: NSFetchedResultsController? {
        didSet(oldfrc)
        {
            if fetchedResultsController != oldfrc {
                fetchedResultsController?.delegate = self
                
                if((title == nil || title == oldfrc?.fetchRequest.entity?.name) && (navigationController == nil || navigationItem.title == nil)) {
                    title = fetchedResultsController?.fetchRequest.entity?.name;
                    print("[\(NSStringFromClass(CoreDataTableViewController.self)) \(NSStringFromSelector(__FUNCTION__))] title set")
                }
                
                if(fetchedResultsController != nil) {
                    if debug {
                        let operation = oldfrc != nil ? "updated" : "set"
                        print("[\(NSStringFromClass(CoreDataTableViewController.self)) \(NSStringFromSelector(__FUNCTION__))] \(operation)")
                    }
                    performFetch();
                }else {
                    tableView.reloadData()
                    if debug {
                        print("[\(NSStringFromClass(CoreDataTableViewController.self)) \(NSStringFromSelector(__FUNCTION__))] reset to nil")
                    }
                }
            }
        }
    }
    
    func fetch()
    {
        if fetchedResultsController != nil {
            if let predicate = fetchedResultsController?.fetchRequest.predicate {
                if debug {
                    print("[\(NSStringFromClass(CoreDataTableViewController.self)) \(NSStringFromSelector(__FUNCTION__))] fetching "  +
                        "\(fetchedResultsController!.fetchRequest.entityName) with predicate \(predicate)")
                }
            } else {
                if debug {
                    print("[\(NSStringFromClass(CoreDataTableViewController.self)) \(NSStringFromSelector(__FUNCTION__))] fetching all "  +
                        "\(fetchedResultsController!.fetchRequest.entityName) (i.e., no predicate)")
                }
            }
            
          do {
            try  fetchedResultsController!.performFetch()
          } catch {
            fatalError("Persistent store error! \(error)")
            }
        }
    }
    
    func performFetch()
    {
        fetch()
        tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        if let count = fetchedResultsController?.sections?.count {
            return count;
        }
        
        return 0;
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rows = 0
        
        if fetchedResultsController?.sections?.count > 0 && section < fetchedResultsController?.sections?.count{
            let sectionInfo : NSFetchedResultsSectionInfo! = fetchedResultsController!.sections![section] as NSFetchedResultsSectionInfo
            rows = sectionInfo.numberOfObjects
        }
        
        return rows;
        
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sectionInfo = fetchedResultsController?.sections?[section] {
            return sectionInfo.name;
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        if let section = fetchedResultsController?.sectionForSectionIndexTitle(title, atIndex: index) {
            return section
        }
        return 0
    }
    
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        if let sectionIndexTitles = fetchedResultsController?.sectionIndexTitles {
            return sectionIndexTitles;
        }
        
        return []

    }
    
    // delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
        atIndex sectionIndex: Int,
        forChangeType type: NSFetchedResultsChangeType) {
            
            switch(type)
            {
            case NSFetchedResultsChangeType.Insert:
                tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Fade)
           
            case NSFetchedResultsChangeType.Delete:
                tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Fade)
             
            case NSFetchedResultsChangeType.Move:
                print("A table item was moved")
          
            case NSFetchedResultsChangeType.Update:
                print("A table item was updated")
     
            }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch(type){
        case NSFetchedResultsChangeType.Insert:
            if(newIndexPath != nil) {
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            }
            break
        case NSFetchedResultsChangeType.Delete:
            if(indexPath != nil) {
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            }
            break
        case NSFetchedResultsChangeType.Update:
            if(indexPath != nil) {
                tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            }
            break
        case NSFetchedResultsChangeType.Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            break
      
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
}