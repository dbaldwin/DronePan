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

protocol CameraControllerDelegate {
    func cameraControllerInError(reason: String)

    func cameraControllerOK(fromError: Bool)

    func cameraControllerNewMedia(filename: String)
}

protocol VideoControllerDelegate {
    func cameraReceivedVideo(videoBuffer: UnsafeMutablePointer<UInt8>, size: Int)
}

class CameraController: NSObject, DJICameraDelegate, SystemUtils {
    let camera: DJICamera

    var delegate: CameraControllerDelegate?
    var videoDelegate: VideoControllerDelegate?

    var status: ControllerStatus = .Normal

    var availableCaptureCount: Int = 0

    init(camera: DJICamera) {
        DDLogInfo("Camera Controller init")

        self.camera = camera

        super.init()

        camera.delegate = self
    }

    /*
    func setPhotoMode() {
        DDLogInfo("Camera Controller setPhotoMode")

        self.status = .Normal

        dispatch_async(self.cameraWorkQueue) {
            self.setPhotoMode(0)
        }
    }
 */

    func hasSpaceForPano(shotCount: Int) -> Bool {
        DDLogDebug("Camera Controller comparing shotCount: \(shotCount) with availableCaptureCount \(availableCaptureCount)")

        return availableCaptureCount == 0 || shotCount <= availableCaptureCount
    }

/*
    private func setPhotoMode(counter: Int) {
        if (status != .Normal) {
            DDLogDebug("Camera Controller setPhotoMode - status was \(status) - returning")

            if (status == .Stopping) {
                self.delegate?.cameraControllerStopped()
            }

            return
        }

        if (counter > maxCount) {
            DDLogWarn("Camera Controller setPhotoMode - counter exceeds max count - aborting")

            self.delegate?.cameraControllerAborted("Failed to set mode")
            return
        }

        let nextCount = counter + 1

        var errorSeen = false

        self.camera.setCameraMode(.ShootPhoto) {
            (error) in

            if let e = error {
                DDLogWarn("Camera Controller setPhotoMode - error seen - \(e)")

                errorSeen = true

                self.setPhotoMode(nextCount)
            }
        }

        if errorSeen {
            return
        }

        delayIfNormal(2) {
            if (self.status == .Normal) {
                if (self.mode == .ShootPhoto) {
                    DDLogDebug("Camera Controller setPhotoMode - OK")

                    self.delegate?.cameraControllerCompleted(false)
                } else {
                    DDLogWarn("Camera Controller hasn't completed yet count: \(counter)")

                    self.setPhotoMode(nextCount)
                }
            } else {
                DDLogDebug("Status changed to \(self.status) while waiting for mode to change")

                if (self.status == .Stopping) {
                    self.delegate?.cameraControllerStopped()
                }
            }
        }
    }
*/

    @objc func camera(camera: DJICamera, didReceiveVideoData videoBuffer: UnsafeMutablePointer<UInt8>, length size: Int) {
        DDLogVerbose("Camera Controller didReceiveVideoData")

        self.videoDelegate?.cameraReceivedVideo(videoBuffer, size: size)
    }

    @objc func camera(camera: DJICamera, didUpdateSystemState systemState: DJICameraSystemState) {
        DDLogVerbose("Camera Controller didUpdateSystemState")

        if (systemState.isCameraOverHeated) {
            DDLogWarn("Camera overheated")
            self.status = .Error
            self.delegate?.cameraControllerInError("Camera overheated")
        }
        if (systemState.isCameraError) {
            DDLogWarn("Camera in error state")
            self.status = .Error
            self.delegate?.cameraControllerInError("Camera in error state")
        }
    }

    func camera(camera: DJICamera, didGenerateNewMediaFile newMedia: DJIMedia) {
        DDLogDebug("Camera Controller didGenerateNewMediaFile")

        self.delegate?.cameraControllerNewMedia(newMedia.fileName)
    }

    func camera(camera: DJICamera, didUpdateSDCardState sdCardState: DJICameraSDCardState) {
        DDLogVerbose("Camera Controller didUpdateSDCardState")

        self.availableCaptureCount = Int(sdCardState.availableCaptureCount)

        var newState: ControllerStatus = .Normal
        var message = ""

        if (sdCardState.hasError) {
            newState = .Error
            message = "SD Card in error state"
        } else if (sdCardState.isReadOnly) {
            newState = .Error
            message = "SD Card is read only"
        } else if (sdCardState.isInvalidFormat) {
            newState = .Error
            message = "SD Card has invalid format"
        } else if (sdCardState.isFull) {
            newState = .Error
            message = "SD Card full"
        } else if (!sdCardState.isInserted) {
            newState = .Error
            message = "SD Card missing"
        } else if (!sdCardState.isFormatted) {
            newState = .Error
            message = "SD Card requires formatting"
        } else if (sdCardState.isFormatting) {
            newState = .Error
            message = "SD Card is currently formatting"
        } else if (sdCardState.isInitializing) {
            newState = .Error
            message = "SD Card is currently initializing"
        }

        if (self.status != newState) {
            DDLogDebug("Camera Controller changing status from \(self.status) to \(newState)")

            if (newState == .Error) {
                DDLogWarn("Camera Controller signal error state with message \(message)")
                self.delegate?.cameraControllerInError(message)
            } else {
                // Don't send message if stopping
                if (newState == .Normal) {
                    DDLogDebug("Camera Controller changed state to normal - signal")

                    self.delegate?.cameraControllerOK(self.status == .Error)
                }
            }

            self.status = newState
        }
    }
}
