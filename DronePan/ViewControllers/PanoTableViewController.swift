/*
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import UIKit
import CoreLocation
import CoreData

protocol PanoSelectionDelegate: class {
    func panoSelected(pano: NSManagedObject)
}

class PanoTableViewController: UITableViewController, PanoSavedDelegate {
    
    var panos = [NSManagedObject]()
    
    weak var delegate: PanoSelectionDelegate?

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        getPanos()
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
        
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.panos.count
        
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! PanoTableViewCell
        
        let pano = self.panos[indexPath.row]
        cell.nameLabel.text = pano.valueForKey("name") as? String
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.LongStyle
        formatter.timeStyle = .MediumStyle
        cell.dateTime.text = formatter.stringFromDate((pano.valueForKey("datetime") as? NSDate)!)

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let selectedPano = self.panos[indexPath.row]
        self.delegate?.panoSelected(selectedPano)
        
    }
    
    func getPanos() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        let sort = NSSortDescriptor(key: "datetime", ascending: false)
        let fetchRequest = NSFetchRequest(entityName: "Pano")
        fetchRequest.sortDescriptors = [sort]
        
        do {
            let results =
                try managedContext.executeFetchRequest(fetchRequest)
            panos = results as! [NSManagedObject]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Setup the delegate so we know when a new pano is saved
        let vc: AddPanoViewController = segue.destinationViewController as! AddPanoViewController
        
        vc.delegate = self
        
    }
    
    // MARK: PanoSavedDelegate from AddPanoViewController
    // Let's refresh the table
    func panoSaved() {
        getPanos()
        self.tableView.reloadData()
        
    }
    

}
