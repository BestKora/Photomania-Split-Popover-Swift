//
//  PhotosCDTVC.swift
//  Photomania
//  Hook up fetchedResultsController to any Photo Fetch Request
//  Use "Photo Cell" as your table view cell's reuse object
//
//

import UIKit

class PhotosCDTVC: CoreDataTableViewController {

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
 
        let cell = tableView.dequeueReusableCellWithIdentifier("Photo Cell", forIndexPath: indexPath)
        let photo = self.fetchedResultsController?.objectAtIndexPath(indexPath) as? Photo
        cell.textLabel?.text = photo?.title
        cell.detailTextLabel?.text = photo?.subtitle == "" ? photo?.unique: photo?.subtitle
        
        return cell
    }
	
	// MARK: - Navigation
	
    func prepareViewController(viewController : UIViewController,
                               forSegue segue : String?,
                      fromIndexPath indexPath : NSIndexPath) {
        
        guard let photo = self.fetchedResultsController?.objectAtIndexPath(indexPath) as? Photo
            else { return }
        var ivc = viewController
                        
        if let vc = viewController as? UINavigationController {
            ivc = vc.visibleViewController!
        }
        guard let ivcm = ivc as? ImageViewController  else { return }
                        
            ivcm.imageURL = NSURL(string: photo.imageURL)
            ivcm.title = photo.title
            ivcm.navigationItem.leftBarButtonItem =
                                         self.splitViewController?.displayModeButtonItem()
            ivcm.navigationItem.leftItemsSupplementBackButton = true
    }
    

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		
        guard let cell = sender as? UITableViewCell,
              let indexPath = self.tableView.indexPathForCell(cell)
            else {return}
				self.prepareViewController(segue.destinationViewController,
                                         forSegue: segue.identifier,
                                    fromIndexPath: indexPath)
	}
}
