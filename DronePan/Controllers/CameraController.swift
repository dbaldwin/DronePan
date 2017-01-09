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
    func cameraControllerCompleted(shotTaken: Bool)

    func cameraControllerAborted(reason: String)

    func cameraControllerStopped()

    func cameraControllerInError(reason: String)

    func cameraControllerOK(fromError: Bool)

    func cameraControllerReset()

    func cameraControllerNewMedia(filename: String)
    
    func cameraExposureValuesUpdated(iso iso: UInt, aperture: DJICameraAperture, shutter: DJICameraShutterSpeed, compensation: DJICameraExposureCompensation)
    
    func cameraExposureModeUpdated(mode: DJICameraExposureMode)
}

protocol VideoControllerDelegate {
    func cameraReceivedVideo(videoBuffer: UnsafeMutablePointer<UInt8>, size: Int)
}

class CameraController: NSObject, DJICameraDelegate {
    let camera: DJICamera
    var model: String?

    var delegate: CameraControllerDelegate?
    var videoDelegate: VideoControllerDelegate?

    var status: ControllerStatus = .Normal

    let maxCount = 5

    let cameraWorkQueue = dispatch_queue_create("com.dronepan.queue.camera", DISPATCH_QUEUE_CONCURRENT)

    var tookShot: Bool = false
    var isShooting: Bool = false
    var isStoring: Bool = false

    var mode: DJICameraMode = .Unknown
    var availableCaptureCount: Int = 0

    init(camera: DJICamera) {
        DDLogInfo("Camera Controller init")

        self.camera = camera

        super.init()

        camera.delegate = self
    }

    func setPhotoMode() {
        DDLogInfo("Camera Controller setPhotoMode")

        self.status = .Normal

        dispatch_async(self.cameraWorkQueue) {
            self.setPhotoMode(0)
        }
    }

    func takeASnap(photoDelayTime: Double) {
        DDLogInfo("Camera Controller takeASnap")

        self.status = .Normal

        self.tookShot = false
        dispatch_async(self.cameraWorkQueue) {
            self.takeASnap(0, photoDelayTime: photoDelayTime)
        }
    }

    func hasSpaceForPano(shotCount: Int) -> Bool {
        DDLogDebug("Camera Controller comparing shotCount: \(shotCount) with availableCaptureCount \(availableCaptureCount)")

        return availableCaptureCount == 0 || shotCount <= availableCaptureCount
    }

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
        
        
        // Check if we can set the focus mode for Mavic
        if(self.camera.isAdjustableFocalPointSupported()) {
            
            self.camera.setLensFocusMode(DJICameraLensFocusMode.Auto) {
                (error) in
            
                if let e = error {
                 
                    DDLogWarn("Camera Controller setLensFocusMode - error seen - \(e)")
                
                } else {
                    
                    DDLogDebug("Camera Controller setLensFocusMode successful")
                    
                    // Since it was successful let's try to set the focus to center
                    self.camera.setLensFocusTarget(CGPointMake(0.5, 0.5)) {
                        (error) in
                        
                        if let e = error {
                            
                            DDLogWarn("Camera Controller setLensFocusTarget - error seen - \(e)")
                            
                        } else {
                            
                            DDLogDebug("Camera Controller setLensFocusTarget successful")
                            
                        }
                    }
                }
            }
            
        }

        if errorSeen {
            return
        }

        delay(2) {
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

    private func takeASnap(counter: Int, photoDelayTime: Double) {
        if (status != .Normal) {
            DDLogDebug("Camera Controller takeASnap - status was \(status) - returning")

            if (status == .Stopping) {
                self.delegate?.cameraControllerStopped()
            }

            return
        }

        if (counter > maxCount) {
            DDLogWarn("Camera Controller takeASnap - counter exceeds max count - aborting")

            self.delegate?.cameraControllerAborted("Failed to take a photo")
            return
        }

        let nextCount = counter + 1

        var errorSeen = false

        // Set the photo mode from the DJI enum
        var djiPhotoMode: DJICameraShootPhotoMode = .Single

        if let model = self.model {
            // Get the photo mode stored in settings
            let photoMode = ModelSettings.photoMode(model)
        
            if (photoMode == 1) {
                djiPhotoMode = .AEB
            }
            
            // photoMode == 2 -> djiPhotoMode = .HDR but this takes too long to process and we timeout
        }
        
        if(counter == 0){
            // Only sleep on first attempt at taking photo
            DDLogDebug("Sleep for \(photoDelayTime) second(s) before taking photo")
            NSThread.sleepForTimeInterval(photoDelayTime)
        }
        
        self.camera.startShootPhoto(djiPhotoMode) {
            (error) in
                if let e = error {
                DDLogWarn("Camera Controller takeASnap - error seen - \(e)")
                
                errorSeen = true
                self.takeASnap(nextCount, photoDelayTime: photoDelayTime)
            }
        }
        

        if errorSeen {
            return
        }

        self.checkTakeASnap(0, counter: counter, photoDelayTime: photoDelayTime)
    }

    private func checkTakeASnap(checkCounter: Int, counter: Int, photoDelayTime: Double) {
        if (status != .Normal) {
            DDLogDebug("Camera Controller checkTakeASnap - status was \(status) - returning")

            if (status == .Stopping) {
                self.delegate?.cameraControllerStopped()
            }

            return
        }

        if (checkCounter > maxCount) {
            DDLogWarn("Camera Controller checkTakeASnap - counter exceeds max count - aborting")

            self.delegate?.cameraControllerAborted("Failed to check photo")
            return
        }

        delay(2) {
            if (self.status == .Normal) {
                if (self.tookShot) {
                    DDLogDebug("Camera Controller checkTakeASnap - OK")

                    self.delegate?.cameraControllerCompleted(true)
                } else if (self.isShooting || self.isStoring) {
                    DDLogDebug("Camera Controller checkTakeASnap - busy - retry")

                    self.checkTakeASnap(checkCounter + 1, counter: counter, photoDelayTime: photoDelayTime)
                } else {
                    DDLogWarn("Camera Controller checkTakeASnap hasn't completed yet count: \(counter)")

                    self.takeASnap(counter + 1, photoDelayTime: photoDelayTime)
                }
            } else {
                DDLogDebug("Status changed to \(self.status) while waiting for photo")

                if (self.status == .Stopping) {
                    self.delegate?.cameraControllerStopped()
                }

            }
        }
    }

    private func delay(delay: Double, closure: () -> ()) {
        if (status != .Normal) {
            DDLogDebug("Camera Controller delay - status was \(status) - returning")

            return
        }

        ControllerUtils.delay(delay, queue: self.cameraWorkQueue, closure: closure)
    }

    @objc func camera(camera: DJICamera, didReceiveVideoData videoBuffer: UnsafeMutablePointer<UInt8>, length size: Int) {
        DDLogVerbose("Camera Controller didReceiveVideoData")

        self.videoDelegate?.cameraReceivedVideo(videoBuffer, size: size)
    }

    @objc func camera(camera: DJICamera, didUpdateSystemState systemState: DJICameraSystemState) {
        DDLogVerbose("Camera Controller didUpdateSystemState")

        if (systemState.isCameraOverHeated) {
            DDLogWarn("Camera overheated")
            self.status = .Error
            self.delegate?.cameraControllerAborted("Camera overheated")
        }
        if (systemState.isCameraError) {
            DDLogWarn("Camera in error state")
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
        DDLogDebug("Camera Controller didGenerateNewMediaFile")

        self.delegate?.cameraControllerNewMedia(newMedia.fileName)

        self.tookShot = true
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
    
    func camera(camera: DJICamera, didUpdateCurrentExposureParameters params: DJICameraExposureParameters) {
        DDLogVerbose("Camera Controller didUpdateCurrentExposureValues")
        
        camera.getExposureModeWithCompletion(){
            (mode, error) in
            if let error = error {
                DDLogWarn("Camera Controller couldn't get exposure mode: \(error)")
            } else {
                self.delegate?.cameraExposureModeUpdated(mode)
            }
        }
        
        self.delegate?.cameraExposureValuesUpdated(iso: params.iso, aperture: params.aperture, shutter: params.shutterSpeed, compensation: params.exposureCompensation)
    }
}
