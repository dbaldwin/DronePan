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

import Foundation
import DJISDK
import CocoaLumberjackSwift

extension String {
    func findRegexGroups(pattern: String) -> [String] {
        var matchedGroups : [String] = []
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let matches = regex.matchesInString(self, options: [], range: NSRange(location:0, length: self.characters.count))

            if let match = matches.first {
                let lastRangeIndex = match.numberOfRanges - 1
                
                if lastRangeIndex >= 1 {
                    for i in 1...lastRangeIndex {
                        let capturedGroupIndex = match.rangeAtIndex(i)
                        let matchedString = (self as NSString).substringWithRange(capturedGroupIndex)
                        matchedGroups.append(matchedString)
                    }
                }
            }
        }
        
        return matchedGroups
    }
}

extension DJICameraExposureMode {
    var description: String {
        get {
            return "\(self)"
        }
    }
}

extension DJICameraAperture {
    var description: String {
        get {
            let parts = "\(self)".findRegexGroups("F([0-9]*)p?([0-9]*)?")
            
            if parts.count == 1 {
                return "f/\(parts[0])"
            } else if parts.count == 2 {
                return "f/\(parts[0]).\(parts[1])"
            } else {
                return "Unknown"
            }
        }
    }
}

extension DJICameraShutterSpeed {
    var description: String {
        get {
            let parts = "\(self)".findRegexGroups("Speed([0-9]*)([_p])([0-9]*)p?([0-9]*)?")
            
            if parts.count >= 3 {
                if parts[1] == "p" {
                    return "\(parts[0]).\(parts[2])s"
                } else if parts[1] == "_" {
                    if parts.count == 4 {
                        return "\(parts[0])/\(parts[2]).\(parts[3])s"
                    } else {
                        return "\(parts[0])/\(parts[2])s"
                    }
                } else {
                    return "Unknown"
                }
            } else {
                return "Unknown"
            }
        }
    }
}

// TODO: Verify if ISO is given by actual value or enum type in DJICameraExposureValues. If given by actual value, the following code is not used in the project and may be deleted.

extension DJICameraISO {
    var description: String {
        get {
            // Special case
            if self == .ISOAuto {
                return "Auto"
            }
            
            let parts = "\(self)".findRegexGroups("ISO([0-9]*)")
            
            if parts.count == 1 {
                return parts[0]
            } else {
                return "Unknown"
            }
        }
    }
}

extension DJICameraExposureCompensation {
    var description: String {
        get {
            // Special case
            if self == .N00 {
                return "0.0"
            }
            
            let parts = "\(self)".findRegexGroups("([NP])([0-9])([0-9])")
            
            if parts.count == 3 {
                if parts[0] == "N" {
                    return "-\(parts[1]).\(parts[2])ev"
                } else if parts[0] == "P" {
                    return "\(parts[1]).\(parts[2])ev"
                } else {
                    return "Unknown"
                }
            } else {
                return "Unknown"
            }
        }
    }
}