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

protocol SegmentTableViewCellDelegate {
    func displayMessage(title: String, message: String)
    func newValueForKey(key: SettingsViewKey, value: String)
}

class SegmentTableViewCell: UITableViewCell {

    var delegate : SegmentTableViewCellDelegate?
    
    var title : String?
    var values : [String]?
    var helpText : String?
    var key : SettingsViewKey?
    var currentValue : String?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    func prepareForDisplay(initialSelection: String) {
        if let title = self.title {
            self.titleLabel.text = title
        }
        
        if let values = self.values {
            self.segmentControl.removeAllSegments()
            
            for (index, value) in values.enumerate() {
                self.segmentControl.insertSegmentWithTitle(value, atIndex: index, animated: false)
                if value == initialSelection {
                    self.segmentControl.selectedSegmentIndex = index
                }
            }
        }
    }
    
    @IBAction func helpButtonClicked(sender: UIButton) {
        if let helpText = self.helpText, titleText = self.titleLabel.text {
            self.delegate?.displayMessage(titleText, message: helpText)
        }
    }
    
    @IBAction func segmentValueChanged(sender: UISegmentedControl) {
        if let key = self.key, value = sender.titleForSegmentAtIndex(sender.selectedSegmentIndex) {
            self.delegate?.newValueForKey(key, value: value)
        }
    }
}
