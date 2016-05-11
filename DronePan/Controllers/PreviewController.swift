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

enum DecoderType {
    case Hardware
    case Software
    case Unknown
}

class PreviewController: VideoControllerDelegate {
    var previewer: VideoPreviewer {
        get {
            return VideoPreviewer.instance()
        }
    }

    func startWithView(view: UIView) {
        previewer.start()
        previewer.setView(view)
    }

    func removeFromView() {
        previewer.unSetView()
    }


    func setMode(product: DJIBaseProduct) -> DecoderType {
        DDLogDebug("Trying to set hardware decoding")

        let hardwareDecodeSupported = previewer.setDecoderWithProduct(product, andDecoderType: .HardwareDecoder)

        if (!hardwareDecodeSupported) {
            DDLogDebug("Hardware decoding failed - try to set software decoding")

            let softwareDecodeSupported = previewer.setDecoderWithProduct(product, andDecoderType: .SoftwareDecoder)

            if (!softwareDecodeSupported) {
                DDLogError("OK - so it doesn't support hardware or software - no idea what to do now")
            } else {
                return .Software
            }
        } else {
            return .Hardware
        }

        return .Unknown
    }

    func cameraReceivedVideo(videoBuffer: UnsafeMutablePointer<UInt8>, size: Int) {
        let pBuffer = UnsafeMutablePointer<UInt8>.alloc(size)
        memcpy(pBuffer, videoBuffer, size)
        previewer.push(pBuffer, length: Int32(size))
    }
}
