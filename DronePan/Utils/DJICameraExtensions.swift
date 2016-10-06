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

extension DJICameraExposureMode {
    var description: String {
        get {
            var text = ""
            switch (self) {
            case .Aperture: text = "Aperture"
            case .Program: text = "Program"
            case .Shutter: text = "Shutter"
            case .Manual: text = "Manual"
            case .Unknown: DDLogWarn("Exposure Mode Enum of Unknown Type!")
            }
            return text
        }
    }
    
}

extension DJICameraAperture {
    var description: String {
        get {
            var text = "f/"
            switch (self) {
            case .F1p7: text += "1.7"
            case .F1p8: text += "1.8"
            case .F2: text += "2"
            case .F2p2: text += "2.2"
            case .F2p5: text += "2.5"
            case .F2p8: text += "2.8"
            case .F3p2: text += "3.2"
            case .F3p5: text += "3.5"
            case .F4: text += "4"
            case .F4p5: text += "4.5"
            case .F5: text += "5"
            case .F5p6: text += "5.6"
            case .F6p3: text += "6.3"
            case .F7p1: text += "7.1"
            case .F8: text += "8"
            case .F9: text += "9"
            case .F10: text += "10"
            case .F11: text += "11"
            case .F13: text += "13"
            case .F14: text += "14"
            case .F16: text += "16"
            case .F18: text += "18"
            case .F20: text += "20"
            case .F22: text += "22"
            case .Unknown: DDLogWarn("Aperture Enum of Unknown Type!")
            }
            return text
        }
    }
}

extension DJICameraShutterSpeed {
    var description: String {
        get {
            var text = ""
            switch (self) {
            case .Speed1_8000: text = "1/8000"
            case .Speed1_6400: text = "1/6400"
            case .Speed1_5000: text = "1/5000"
            case .Speed1_4000: text = "1/4000"
            case .Speed1_3200: text = "1/3200"
            case .Speed1_2500: text = "1/2500"
            case .Speed1_2000: text = "1/2000"
            case .Speed1_1600: text = "1/1600"
            case .Speed1_1250: text = "1/1250"
            case .Speed1_1000: text = "1/1000"
            case .Speed1_800: text = "1/800"
            case .Speed1_640: text = "1/640"
            case .Speed1_500: text = "1/500"
            case .Speed1_400: text = "1/400"
            case .Speed1_320: text = "1/320"
            case .Speed1_240: text = "1/240"
            case .Speed1_200: text = "1/200"
            case .Speed1_160: text = "1/160"
            case .Speed1_120: text = "1/120"
            case .Speed1_100: text = "1/100"
            case .Speed1_80: text = "1/80"
            case .Speed1_60: text = "1/60"
            case .Speed1_50: text = "1/50"
            case .Speed1_40: text = "1/40"
            case .Speed1_30: text = "1/30"
            case .Speed1_25: text = "1/25"
            case .Speed1_20: text = "1/20"
            case .Speed1_15: text = "1/15"
            case .Speed1_12p5: text = "1/12.5"
            case .Speed1_10: text = "1/10"
            case .Speed1_8: text = "1/8"
            case .Speed1_6p25: text = "1/6.25"
            case .Speed1_5: text = "1/5"
            case .Speed1_4: text = "1/4"
            case .Speed1_3: text = "1/3"
            case .Speed1_2p5: text = "1/2.5"
            case .Speed1_2: text = "1/2"
            case .Speed1_1p67: text = "1/1.67"
            case .Speed1_1p25: text = "1/1.25"
            case .Speed1p0: text = "1.0"
            case .Speed1p3: text = "1.3"
            case .Speed1p6: text = "1.6"
            case .Speed2p0: text = "2.0"
            case .Speed2p5: text = "2.5"
            case .Speed3p0: text = "3.0"
            case .Speed3p2: text = "3.2"
            case .Speed4p0: text = "4.0"
            case .Speed5p0: text = "5.0"
            case .Speed6p0: text = "6.0"
            case .Speed7p0: text = "7.0"
            case .Speed8p0: text = "8.0"
            case .Speed9p0: text = "9.0"
            case .Speed10p0: text = "10.0"
            case .Speed13p0: text = "13.0"
            case .Speed15p0: text = "15.0"
            case .Speed20p0: text = "20.0"
            case .Speed25p0: text = "25.0"
            case .Speed30p0: text = "30.0"
            case .SpeedUnknown: DDLogWarn("Shutter Speed Enum of Unknown Type!")
            }
            text += "s"
            return text
        }
    }
    
}

// TODO: Verify if ISO is given by actual value or enum type in DJICameraExposureValues. If given by actual value, the following code is not used in the project and may be deleted.

extension DJICameraISO {
    var description: String {
        get {
            var text = ""
            switch (self) {
            case .ISOAuto: text = "Auto"
            case .ISO100: text = "100"
            case .ISO200: text = "200"
            case .ISO400: text = "400"
            case .ISO800: text = "800"
            case .ISO1600: text = "1600"
            case .ISO3200: text = "3200"
            case .ISO6400: text = "6400"
            case .ISO12800: text = "12800"
            case .ISO25600: text = "25600"
            case .ISOUnknown: DDLogWarn("ISO Enum of Unknown Type!")
            }
            return text
        }
    }
}

extension DJICameraExposureCompensation {
    var description: String {
        get {
            var text = ""
            switch (self) {
            case .N50: text = "-5.0"
            case .N47: text = "-4.7"
            case .N43: text = "-4.3"
            case .N40: text = "-4.0"
            case .N37: text = "-3.7"
            case .N33: text = "-3.3"
            case .N30: text = "-3.0"
            case .N27: text = "-2.7"
            case .N23: text = "-2.3"
            case .N20: text = "-2.0"
            case .N17: text = "-1.7"
            case .N13: text = "-1.3"
            case .N10: text = "-1.0"
            case .N07: text = "-0.7"
            case .N03: text = "-0.3"
            case .N00: text = "0.0"
            case .P50: text = "5.0"
            case .P47: text = "4.7"
            case .P43: text = "4.3"
            case .P40: text = "4.0"
            case .P37: text = "3.7"
            case .P33: text = "3.3"
            case .P30: text = "3.0"
            case .P27: text = "2.7"
            case .P23: text = "2.3"
            case .P20: text = "2.0"
            case .P17: text = "1.7"
            case .P13: text = "1.3"
            case .P10: text = "1.0"
            case .P07: text = "0.7"
            case .P03: text = "0.3"
            case .Unknown: DDLogWarn("Exposure Compensation Enum of Unknown Type!")
            }
            text += "ev"
            return text
        }
    }
}
