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
            switch self {
            case .Aperture: return "Aperture"
            case .Manual:   return "Manual"
            case .Program:  return "Program"
            case .Shutter:  return "Shutter"
            case .Unknown:  return "Unknown"
            }
        }
    }
}

extension DJICameraAperture {
    var description : String {
        get {
            switch self {
            case .F1p6:    return "f/1.6"
            case .F1p7:    return "f/1.7"
            case .F1p8:    return "f/1.8"
            case .F2:      return "f/2"
            case .F2p2:    return "f/2.2"
            case .F2p4:    return "f/2.4"
            case .F2p5:    return "f/2.5"
            case .F2p8:    return "f/2.8"
            case .F3p2:    return "f/3.2"
            case .F3p4:    return "f/3.4"
            case .F3p5:    return "f/3.5"
            case .F4:      return "f/4"
            case .F4p5:    return "f/4.5"
            case .F4p8:    return "f/4.8"
            case .F5:      return "f/5"
            case .F5p6:    return "f/5.6"
            case .F6p3:    return "f/6.3"
            case .F6p8:    return "f/6.8"
            case .F7p1:    return "f/7.1"
            case .F8:      return "f/8"
            case .F9:      return "f/9"
            case .F9p6:    return "f/9.6"
            case .F10:     return "f/10"
            case .F11:     return "f/11"
            case .F13:     return "f/13"
            case .F14:     return "f/14"
            case .F16:     return "f/16"
            case .F18:     return "f/18"
            case .F20:     return "f/20"
            case .F22:     return "f/22"
            case .Unknown: return "Unknown"
            }
        }
    }
}


extension DJICameraShutterSpeed {
    var description : String {
        get {
            switch self {
            case .Speed1_8000:  return "1/8000s"
            case .Speed1_6400:  return "1/6400s"
            case .Speed1_6000:  return "1/6000s"
            case .Speed1_5000:  return "1/5000s"
            case .Speed1_4000:  return "1/4000s"
            case .Speed1_3200:  return "1/3200s"
            case .Speed1_3000:  return "1/3000s"
            case .Speed1_2500:  return "1/2500s"
            case .Speed1_2000:  return "1/2000s"
            case .Speed1_1600:  return "1/1600s"
            case .Speed1_1500:  return "1/1500s"
            case .Speed1_1250:  return "1/1250s"
            case .Speed1_1000:  return "1/1000s"
            case .Speed1_800:   return "1/800s"
            case .Speed1_725:   return "1/725s"
            case .Speed1_640:   return "1/640s"
            case .Speed1_500:   return "1/500s"
            case .Speed1_400:   return "1/400s"
            case .Speed1_350:   return "1/350s"
            case .Speed1_320:   return "1/320s"
            case .Speed1_250:   return "1/250s"
            case .Speed1_240:   return "1/240s"
            case .Speed1_200:   return "1/200s"
            case .Speed1_180:   return "1/180s"
            case .Speed1_160:   return "1/160s"
            case .Speed1_125:   return "1/125s"
            case .Speed1_120:   return "1/120s"
            case .Speed1_100:   return "1/100s"
            case .Speed1_90:   return "1/90s"
            case .Speed1_80:    return "1/80s"
            case .Speed1_60:    return "1/60s"
            case .Speed1_50:    return "1/50s"
            case .Speed1_40:    return "1/40s"
            case .Speed1_30:    return "1/30s"
            case .Speed1_25:    return "1/25s"
            case .Speed1_20:    return "1/20s"
            case .Speed1_15:    return "1/15s"
            case .Speed1_12p5:  return "1/12.5s"
            case .Speed1_10:    return "1/10s"
            case .Speed1_8:     return "1/8s"
            case .Speed1_6p25:  return "1/6.25s"
            case .Speed1_5:     return "1/5s"
            case .Speed1_4:     return "1/4s"
            case .Speed1_3:     return "1/3s"
            case .Speed1_2p5:   return "1/2.5s"
            case .Speed1_2:     return "1/2s"
            case .Speed1_1p67:  return "1/1.67s"
            case .Speed1_1p25:  return "1/1.25s"
            case .Speed1p0:     return "1.0s"
            case .Speed1p3:     return "1.3s"
            case .Speed1p6:     return "1.6s"
            case .Speed2p0:     return "2.0s"
            case .Speed2p5:     return "2.5s"
            case .Speed3p0:     return "3.0s"
            case .Speed3p2:     return "3.2s"
            case .Speed4p0:     return "4.0s"
            case .Speed5p0:     return "5.0s"
            case .Speed6p0:     return "6.0s"
            case .Speed7p0:     return "7.0s"
            case .Speed8p0:     return "8.0s"
            case .Speed9p0:     return "9.0s"
            case .Speed10p0:    return "10.0s"
            case .Speed13p0:    return "13.0s"
            case .Speed15p0:    return "15.0s"
            case .Speed20p0:    return "20.0s"
            case .Speed25p0:    return "25.0s"
            case .Speed30p0:    return "30.0s"
            case .SpeedUnknown: return "Unknown"
            }
        }
    }
    
}

// TODO: Verify if ISO is given by actual value or enum type in DJICameraExposureValues. If given by actual value, the following code is not used in the project and may be deleted.

extension DJICameraISO {
    var description : String {
        get {
            switch self {
            case .ISOAuto:    return "Auto"
            case .ISO100:     return "100"
            case .ISO200:     return "200"
            case .ISO400:     return "400"
            case .ISO800:     return "800"
            case .ISO1600:    return "1600"
            case .ISO3200:    return "3200"
            case .ISO6400:    return "6400"
            case .ISO12800:   return "12800"
            case .ISO25600:   return "25600"
            case .ISOUnknown: return "Unknown"
            }
        }
    }
}

extension DJICameraExposureCompensation {
    var description: String {
        get {
            switch self {
            case N50:     return "-5.0ev"
            case N47:     return "-4.7ev"
            case N43:     return "-4.3ev"
            case N40:     return "-4.0ev"
            case N37:     return "-3.7ev"
            case N33:     return "-3.3ev"
            case N30:     return "-3.0ev"
            case N27:     return "-2.7ev"
            case N23:     return "-2.3ev"
            case N20:     return "-2.0ev"
            case N17:     return "-1.7ev"
            case N13:     return "-1.3ev"
            case N10:     return "-1.0ev"
            case N07:     return "-0.7ev"
            case N03:     return "-0.3ev"
            case N00:     return "0.0ev"
            case P03:     return "+0.3ev"
            case P07:     return "+0.7ev"
            case P10:     return "+1.0ev"
            case P13:     return "+1.3ev"
            case P17:     return "+1.7ev"
            case P20:     return "+2.0ev"
            case P23:     return "+2.3ev"
            case P27:     return "+2.7ev"
            case P30:     return "+3.0ev"
            case P33:     return "+3.3ev"
            case P37:     return "+3.7ev"
            case P40:     return "+4.0ev"
            case P43:     return "+4.3ev"
            case P47:     return "+4.7ev"
            case P50:     return "+5.0ev"
            case Unknown: return "Unknown"
            }
        }
    }
}
