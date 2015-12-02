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
import Foundation
import UIKit
import CoreData


class CoreDataTableViewController : UITableViewController, NSFetchedResultsControllerDelegate {
        let debug = false
    // MARK: - Instance variables

    var fetchedResultsController: NSFetchedResultsController? {
        didSet(oldfrc)
        {
            if fetchedResultsController != oldfrc {
                fetchedResultsController?.delegate = self
                
                if((title == nil || title == oldfrc?.fetchRequest.entity?.name) && (navigationController == nil || navigationItem.title == nil)) {
                    if debug {
                    title = fetchedResultsController?.fetchRequest.entity?.name;
                    print("[\(NSStringFromClass(CoreDataTableViewController.self)) \(NSStringFromSelector(__FUNCTION__))] title set")
                    }
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


    // MARK: - Fetching

   private func fetch()
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
            } catch let error as NSError {
                print("Error: \(error.localizedDescription)")
                fatalError("Persistent store error! \(error)")
            }
        }
    }

    func performFetch() {
        fetch()
        self.tableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let count = fetchedResultsController?.sections?.count {
            return count;
        }
        
        return 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rows = 0
        
        if fetchedResultsController?.sections?.count > 0 && section < fetchedResultsController?.sections?.count{
            let sectionInfo : NSFetchedResultsSectionInfo! = fetchedResultsController!.sections![section] as NSFetchedResultsSectionInfo
            rows = sectionInfo.numberOfObjects
        }
        
        return rows

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

    // MARK: - NSFetchedResultsControllerDelegate

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        let indexSet = NSIndexSet(index: sectionIndex)
        switch type {
            case NSFetchedResultsChangeType.Insert:
                self.tableView.insertSections(indexSet, withRowAnimation: UITableViewRowAnimation.Fade)
            
            case NSFetchedResultsChangeType.Delete:
                self.tableView.deleteSections(indexSet, withRowAnimation: UITableViewRowAnimation.Fade)
            
            case NSFetchedResultsChangeType.Update:
                 print("A table item was updated")

            case NSFetchedResultsChangeType.Move:
                 print("A table item was moved")
        }
    }
    
   func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {

        switch type {
            case NSFetchedResultsChangeType.Insert:
                if(newIndexPath != nil) {
                    tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            }
            case NSFetchedResultsChangeType.Delete:
                if(indexPath != nil) {
                    tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
                }
            case NSFetchedResultsChangeType.Update:
            if(indexPath != nil) {
                tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            }
        
            case NSFetchedResultsChangeType.Move:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
        }
    }
  
    // MARK: - Private

  func setUpFetchedResultsController() {
        self.fetchedResultsController!.delegate = self
        if self.title == nil && (self.navigationController == nil || self.navigationItem.title == nil) {
            self.title = self.fetchedResultsController?.fetchRequest.entity?.name ?? ""
        }
        self.performFetch()
    }
}
