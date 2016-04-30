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

@objc class PanoramaController: NSObject {
    class func pitchesForLoop(skyRow skyRow: Bool, type: ProductType, rowCount: Int) -> Array<Double> {
        let min: Double = -60
        let max: Double = skyRow ? 30 : 0
        let count = skyRow ? rowCount + 1 : rowCount

        let interval = Double(max - min) / Double(count - 1)

        let values = (0 ..< count).map({
            max - (Double($0) * interval)
        })

        return type == .Aircraft ? values : values.reverse()
    }

    class func yawAngles(count count: Int, heading: Double) -> [Double] {
        let yaw_angle = 360.0 / Double(count)

        return (0 ..< count).map({
            heading + (yaw_angle * Double($0 + 1))
        }).map({
            (angle: Double) -> Double in
            angle > 360 ? angle - 360.0 : angle
        })
    }

    class func headingTo360(heading: Double) -> Double {
        return heading >= 0 ? heading : heading + 360.0
    }
}
