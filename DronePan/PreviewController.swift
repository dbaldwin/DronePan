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

@objc class PreviewController: NSObject, VideoControllerDelegate {

    func startWithView(view: UIView) {
        VideoPreviewer.instance().start()
        VideoPreviewer.instance().setView(view)
    }

    func removeFromView() {
        VideoPreviewer.instance().unSetView()
    }


    func setMode(product: DJIBaseProduct) {
        DDLogDebug("Trying to set hardware decoding")

        let hardwareDecodeSupported = VideoPreviewer.instance().setDecoderWithProduct(product, andDecoderType: .HardwareDecoder)

        if (!hardwareDecodeSupported) {
            DDLogDebug("Hardware decoding failed - try to set software decoding")

            let softwareDecodeSupported = VideoPreviewer.instance().setDecoderWithProduct(product, andDecoderType: .SoftwareDecoder)

            if (!softwareDecodeSupported) {
                DDLogError("OK - so it doesn't support hardware or software - no idea what to do now")
            }
        }
    }

    func cameraReceivedVideo(videoBuffer: UnsafeMutablePointer<UInt8>, size: Int) {
        let pBuffer = UnsafeMutablePointer<UInt8>.alloc(size)
        memcpy(pBuffer, videoBuffer, size)
        VideoPreviewer.instance().push(pBuffer, length: Int32(size))
    }
}
