//
//  PhotographersCDTVC.swift
//  Photomania
//
//

import UIKit
import CoreData

class PhotographersCDTVC: CoreDataTableViewController {
    var coreDataStack: CoreDataStack! {
        didSet {
            let request = NSFetchRequest(entityName: "Photographer")
            request.predicate = nil
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))]
            
            self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: coreDataStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        }
    }

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("Photographer Cell", forIndexPath: indexPath)
        let photographer = self.fetchedResultsController?.objectAtIndexPath(indexPath) as? Photographer
        
        cell.textLabel?.text = photographer?.name
        cell.detailTextLabel?.text = "\(photographer?.photos.count ?? 0) photos"
        
        return cell

	}
	
	
	// MARK: - Navigation
		
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let cell = sender as? UITableViewCell,
              let indexPath = self.tableView.indexPathForCell(cell),
              let photographer = self.fetchedResultsController?.objectAtIndexPath(indexPath) as? Photographer,
              let vc = segue.destinationViewController as? PhotosByPhotographerCDTVC
        else {return}
        vc.photographer = photographer
	}
}
