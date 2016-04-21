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

@objc protocol CameraControllerDelegate {
    func cameraControllerCompleted(shotTaken: Bool)

    func cameraControllerAborted(reason: String)

    func cameraControllerReset()

    func cameraReceivedVideo(videoBuffer: UnsafeMutablePointer<UInt8>, size: Int)
}

@objc class CameraController: NSObject, DJICameraDelegate {
    let camera: DJICamera

    var delegate: CameraControllerDelegate?
    var status : ControllerStatus = .Normal

    let maxCount = 5

    let cameraWorkQueue = dispatch_queue_create("com.dronepan.queue.camera", DISPATCH_QUEUE_CONCURRENT)

    var tookShot: Bool = false
    var isShooting: Bool = false
    var isStoring: Bool = false

    var mode: DJICameraMode = .Unknown
    

    init(camera: DJICamera) {
        self.camera = camera

        super.init()

        camera.delegate = self
    }

    func setPhotoMode() {
        self.status = .Normal
        
        dispatch_async(self.cameraWorkQueue) {
            self.setPhotoMode(0)
        }
    }

    func takeASnap() {
        self.status = .Normal

        self.tookShot = false
        dispatch_async(self.cameraWorkQueue) {
            self.takeASnap(0)
        }
    }

    private func setPhotoMode(counter: Int) {
        if (status != .Normal) {
            return
        }
        
        if (counter > maxCount) {
            self.delegate?.cameraControllerAborted("Failed to set mode")
            return
        }

        let nextCount = counter + 1

        self.camera.setCameraMode(.ShootPhoto) {
            (error) in

            if let e = error {
                NSLog("Error setting photo mode: \(e)")

                self.setPhotoMode(nextCount)
            }
        }

        delay(2) {
            if (self.mode == .ShootPhoto) {
                self.delegate?.cameraControllerCompleted(false)
            } else {
                NSLog("Camera hasn't set mode yet count: \(counter)")

                self.setPhotoMode(nextCount)
            }
        }
    }

    private func takeASnap(counter: Int) {
        if (status != .Normal) {
            return
        }

        if (counter > maxCount) {
            self.delegate?.cameraControllerAborted("Failed to take a photo")
            return
        }

        let nextCount = counter + 1

        self.camera.startShootPhoto(.Single) {
            (error) in
            if let e = error {
                NSLog("Error taking a photo: \(e)")

                self.takeASnap(nextCount)
            }
        }

        self.checkTakeASnap(0, counter: counter)
    }

    private func checkTakeASnap(checkCounter: Int, counter: Int) {
        if (status != .Normal) {
            return
        }

        if (checkCounter > maxCount) {
            self.delegate?.cameraControllerAborted("Failed to check photo")
            return
        }

        delay(2) {
            if (self.tookShot) {
                self.delegate?.cameraControllerCompleted(true)
            } else if (self.isShooting || self.isStoring) {
                self.checkTakeASnap(checkCounter + 1, counter: counter)
            } else {
                NSLog("Camera hasn't taken shot yet count: \(counter)")

                self.takeASnap(counter + 1)
            }
        }
    }

    private func delay(delay: Double, closure: () -> ()) {
        if (status != .Normal) {
            return
        }

        ControllerUtils.delay(delay, queue: self.cameraWorkQueue, closure: closure)
    }

    func camera(camera: DJICamera, didReceiveVideoData videoBuffer: UnsafeMutablePointer<UInt8>, length size: Int) {
        self.delegate?.cameraReceivedVideo(videoBuffer, size: size)
    }

    func camera(camera: DJICamera, didUpdateSystemState systemState: DJICameraSystemState) {
        if (systemState.isCameraOverHeated) {
            self.status = .Error
            self.delegate?.cameraControllerAborted("Camera overheated")
        }
        if (systemState.isCameraError) {
            self.status = .Error
            self.delegate?.cameraControllerAborted("Camera in error state")
        }
        
        self.mode = systemState.mode

        self.isShooting = systemState.isShootingSinglePhoto ||
                systemState.isShootingSinglePhotoInRAWFormat ||
                systemState.isShootingBurstPhoto ||
                systemState.isShootingIntervalPhoto

        self.isStoring = systemState.isStoringPhoto
    }

    func camera(camera: DJICamera, didGenerateNewMediaFile newMedia: DJIMedia) {
        self.tookShot = true
    }

    func camera(camera: DJICamera, didUpdateSDCardState sdCardState: DJICameraSDCardState) {
        if (sdCardState.hasError) {
            self.status = .Error
            self.delegate?.cameraControllerAborted("SD Card in error state")
        }

        if (sdCardState.isReadOnly) {
            self.status = .Error
            self.delegate?.cameraControllerAborted("SD Card is read only")
        }
        
        if (sdCardState.isInvalidFormat) {
            self.status = .Error
            self.delegate?.cameraControllerAborted("SD Card has invalid format")
        }

        if (sdCardState.isFull) {
            self.status = .Error
            self.delegate?.cameraControllerAborted("SD Card full")
        }
        
        if (!sdCardState.isInserted) {
            self.status = .Error
            self.delegate?.cameraControllerAborted("SD Card missing")
        }

        if (!sdCardState.isFormatted) {
            self.status = .Error
            self.delegate?.cameraControllerAborted("SD Card requires formatting")
        }

        if (!sdCardState.isFormatting) {
            self.status = .Error
            self.delegate?.cameraControllerAborted("SD Card is currently formatting")
        }

        if (!sdCardState.isInitializing) {
            self.status = .Error
            self.delegate?.cameraControllerAborted("SD Card is currently initializing")
        }
    }
}
