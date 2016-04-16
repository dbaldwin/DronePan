import Foundation

import DJISDK

@objc protocol CameraControllerDelegate {
    func cameraControllerCompleted()

    func cameraControllerAborted()

    func cameraControllerReset()

    func cameraReceivedVideo(videoBuffer: UnsafeMutablePointer<UInt8>, size: Int)
}

@objc class CameraController: NSObject, DJICameraDelegate {
    let camera: DJICamera

    var delegate: CameraControllerDelegate?

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
        dispatch_async(self.cameraWorkQueue) {
            self.setPhotoMode(0)
        }
    }

    func takeASnap() {
        self.tookShot = false
        dispatch_async(self.cameraWorkQueue) {
            self.takeASnap(0)
        }
    }

    private func setPhotoMode(counter: Int) {
        if (counter > maxCount) {
            self.delegate?.cameraControllerAborted()
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
                self.delegate?.cameraControllerCompleted()
            } else {
                NSLog("Camera hasn't set mode yet count: \(counter)")

                self.setPhotoMode(nextCount)
            }
        }
    }

    private func takeASnap(counter: Int) {
        if (counter > maxCount) {
            self.delegate?.cameraControllerAborted()
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
        if (checkCounter > maxCount) {
            self.delegate?.cameraControllerAborted()
            return
        }

        delay(2) {
            if (self.tookShot) {
                self.delegate?.cameraControllerCompleted()
            } else if (self.isShooting || self.isStoring) {
                self.checkTakeASnap(checkCounter + 1, counter: counter)
            } else {
                NSLog("Camera hasn't taken shot yet count: \(counter)")

                self.takeASnap(counter + 1)
            }
        }
    }

    private func delay(delay: Double, closure: () -> ()) {
        ControllerUtils.delay(delay, queue: self.cameraWorkQueue, closure: closure)
    }

    func camera(camera: DJICamera, didReceiveVideoData videoBuffer: UnsafeMutablePointer<UInt8>, length size: Int) {
        self.delegate?.cameraReceivedVideo(videoBuffer, size: size)
    }

    func camera(camera: DJICamera, didUpdateSystemState systemState: DJICameraSystemState) {
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

    func camera(camera: DJICamera, didGenerateTimeLapsePreview previewImage: UIImage) {
        // Might be able to use this for progress later
    }

    func camera(camera: DJICamera, didUpdateSDCardState sdCardState: DJICameraSDCardState) {
        // TODO - check full, error etc
    }
}
