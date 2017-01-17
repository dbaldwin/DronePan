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

import CocoaLumberjackSwift

protocol SliderTableViewCellDelegate {
    func displayMessage(title: String, message: String)
    func newValueForKey(key: SettingsViewKey, value: Int)
}

class SliderTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var slider: UISlider!    

    var delegate : SliderTableViewCellDelegate?

    var title : String?
    var min : Int = 0
    var max : Int = 0
    var step : Int = 1
    var divider: Int = 1 // Used for division of integers in case decimal is needed
    var helpText : String?
    var key : SettingsViewKey?

    func setTitleText(value : Int) {
        if let title = self.title {
            if divider != 1 {
                let divided = Double(Double(value) / Double(divider))
                self.titleLabel.text = "\(title) \(divided)"
            }
            else {
                self.titleLabel.text = "\(title) \(value)"
            }
        }
    }
    
    func prepareForDisplay(initialValue: Int) {
        setTitleText(initialValue)
        
        self.slider.minimumValue = Float(self.min)
        self.slider.maximumValue = Float(self.max)
        self.slider.value = Float(initialValue)
    }
    
    @IBAction func helpButtonClicked(sender: UIButton) {
        if let helpText = self.helpText, titleText = self.titleLabel.text {
            self.delegate?.displayMessage(titleText, message: helpText)
        }
    }
    
    @IBAction func sliderValueChanged(sender: UISlider) {
        let roundedValue = round(sender.value / Float(step)) * Float(step)
        
        sender.value = roundedValue

        let intValue = Int(roundedValue)
        
        setTitleText(intValue)
        
        if let key = self.key {
            self.delegate?.newValueForKey(key, value: intValue)
        }
    }
}
