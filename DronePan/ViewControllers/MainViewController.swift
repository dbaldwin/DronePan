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

import UIKit
import DJISDK

import CocoaLumberjackSwift

class MainViewController: UIViewController, Analytics {
    @IBOutlet weak var batteryLabel: UILabel!
    @IBOutlet weak var batteryIcon: UIImageView!

    @IBOutlet weak var cameraView: UIView!

    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var warningView: UIView!
    @IBOutlet weak var warningOffset: NSLayoutConstraint!

    @IBOutlet weak var sequenceLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var satelliteLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!

    @IBOutlet weak var acYawLabel: UILabel!
    @IBOutlet weak var gimbalYawLabel: UILabel!
    @IBOutlet weak var gimbalPitchLabel: UILabel!
    @IBOutlet weak var gimbalRollLabel: UILabel!

    @IBOutlet weak var cameraModeLabel: UILabel!
    @IBOutlet weak var cameraApertureLabel: UILabel!
    @IBOutlet weak var cameraShutterSpeedLabel: UILabel!
    @IBOutlet weak var cameraISOLabel: UILabel!
    @IBOutlet weak var cameraExposureCompensationLabel: UILabel!

    @IBOutlet weak var connectionStatusIndicator: UIImageView!

    @IBOutlet weak var startButton: UIButton!

    @IBOutlet weak var panoProgressBar: UIProgressView!

    var rcInFMode = false

    var product: DJIBaseProduct?
    var firmwareVersion: String = ""

    var connectionController: ConnectionController?
    var previewController: PreviewController?

    var batteryController: BatteryController?
    var panoramaController: PanoramaController?
    
    var animationDuration = 1.0
    
    var currentWarning = ""
    var currentProgress = 0.0
    
    var currentPanorama : Panorama?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.previewController = PreviewController(previewer: VideoPreviewerInstance())
        self.panoramaController = PanoramaController()
        self.panoramaController!.delegate = self
        self.panoramaController!.cameraControlsDelegate = self

        hideWarning()

        /*
        // TODO: this should be tested
        #ifndef DEBUG
        [self.startButton setEnabled:NO];
    #endif
 */

        self.rcInFMode = false

        self.resetLabels()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        DDLogInfo("Showing main window")
        trackScreenView("MainViewController")

        self.previewController?.startWithView(self.cameraView)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        DDLogInfo("Hiding main window")

        self.previewController?.removeFromView()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        self.connectionController = ConnectionController()
        self.connectionController!.delegate = self
        self.connectionController!.start()
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    func showWarning(warning : String) {
        currentWarning = warning
        
        // TODO: this view should be a custom class that has a set of messages that rotate
        if (self.warningOffset.constant == 0) {
            self.warningView.alpha = 1
            dispatch_async(dispatch_get_main_queue()) {
                self.warningLabel.text = self.currentWarning

                self.scrollView(self.cameraView, toOffset: -self.warningView.frame.size.height, usingConstraint: self.warningOffset)
            }
        }
    }

    func hideWarning() {
        currentWarning = ""
        
        if (self.warningOffset.constant != 0) {
            dispatch_async(dispatch_get_main_queue()) {
                self.scrollView(self.cameraView, toOffset: 0, usingConstraint: self.warningOffset) {
                    self.warningView.alpha = 0
                }
            }
        }
    }

    func scrollView(view: UIView, toOffset offset: CGFloat, usingConstraint constraint: NSLayoutConstraint, completion: (() -> Void)? = nil) {
        constraint.constant = offset

        view.setNeedsUpdateConstraints()

        UIView.animateWithDuration(animationDuration, animations: {
            view.layoutIfNeeded()
        }) {
            (completed) in
            completion?()
        }
    }

    func setSequence(current: Int? = nil, count: Int? = nil) {
        if let current = current, count = count {
            self.sequenceLabel.text = "\(current)/\(count)"

            self.currentProgress = Double(current) / Double(count)
        } else {
            self.sequenceLabel.text = ""

            self.currentProgress = 0.0
        }

        self.panoProgressBar.setProgress(Float(currentProgress), animated: true)
    }

    func setAltitude(altitude: Int? = nil) {
        if let altitude = altitude {
            self.altitudeLabel.text = (ControllerUtils.displayDistance(altitude))
        } else {
            self.altitudeLabel.text = ""
        }
    }

    func setSatellites(satellites: Int? = nil) {
        if let satellites = satellites {
            self.satelliteLabel.text = "\(satellites)"
        } else {
            self.satelliteLabel.text = ""
        }
    }

    func setDistance(distance: Int? = nil) {
        if let distance = distance {
            self.distanceLabel.text = (ControllerUtils.displayDistance(distance))
        } else {
            self.distanceLabel.text = ""
        }
    }

    func setBattery(batteryPercent: Int? = nil) {
        if let batteryPercent = batteryPercent {
            self.batteryLabel.text = "\(batteryPercent)%"
            self.batteryIcon.image = ControllerUtils.batteryImageForLevel(batteryPercent)
        } else {
            self.batteryLabel.text = ""
            self.batteryIcon.image = ControllerUtils.batteryImageForLevel()
        }
    }

    func setCameraMode(mode: DJICameraExposureMode? = nil) {
        if let mode = mode {
            self.cameraModeLabel.text = "Mode: \(mode.description)"
        } else {
            self.cameraModeLabel.text = "Mode: Unknown"
        }
    }
    
    func setCameraAperture(aperture: DJICameraAperture? = nil) {
        if let aperture = aperture {
            self.cameraApertureLabel.text = "Aperture: \(aperture.description)"
        } else {
            self.cameraApertureLabel.text = "Aperture: Unknown"
        }
    }
    
    func setCameraSpeed(speed: DJICameraShutterSpeed? = nil) {
        if let speed = speed {
            self.cameraShutterSpeedLabel.text = "Speed: \(speed.description)"
        } else {
            self.cameraShutterSpeedLabel.text = "Speed: Unknown"
        }
    }
    
    func setCameraISO(iso: DJICameraISO? = nil) {
        if let iso = iso {
            self.cameraISOLabel.text = "ISO: \(iso.rawValue)"
        } else {
            self.cameraISOLabel.text = "ISO: Unknown"
        }
    }
    
    func setCameraExposureCompensation(comp: DJICameraExposureCompensation? = nil) {
        if let comp = comp {
            self.cameraExposureCompensationLabel.text = "EC: \(comp.description)"
        } else {
            self.cameraExposureCompensationLabel.text = "EC: Unknown"
        }
    }
    
    func resetLabels() {
        setSequence()
        setAltitude()
        setSatellites()
        setDistance()
        setBattery()
        
        setCameraMode()
        setCameraAperture()
        setCameraSpeed()
        setCameraISO()
        setCameraExposureCompensation()
    }

    func resetInfoLabels() {
        self.acYawLabel.text = "Aircraft Yaw: ----"
        self.gimbalYawLabel.text = "Gimbal Yaw: ----"
        self.gimbalPitchLabel.text = "Gimbal Pitch: ----"
        self.gimbalRollLabel.text = "Gimbal Roll: ----"
    }

    @IBAction func startPanorama(sender: UIButton) {
        if let panoramaController = self.panoramaController {
            if (panoramaController.panoRunning.state) {
                DDLogInfo("Stopping pano from button")

                self.trackEvent(category: "Panorama", action: "Running", label: "Started by user")

                panoramaController.stop()
            } else {
                DDLogInfo("Starting pano from button")

                self.trackEvent(category: "Panorama", action: "Running", label: "Stopped by user")

                panoramaController.start()
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else {
            DDLogDebug("Segue without identifier seen - ignoring")
            return
        }
        
        switch identifier {
            
        case "settingsSegue":
            
            if let settings = segue.destinationViewController as? SettingsViewController {
                settings.presentationController!.delegate = self
                #if DEBUG
                    if let model = self.panoramaController?.model, type = self.panoramaController?.type {
                        settings.model = model
                        settings.type = type
                    } else {
                        settings.model = "Simulator"
                        settings.type = .Aircraft
                    }
                #else
                    if let model = self.panoramaController?.model, type = self.panoramaController?.type {
                        settings.model = model
                        settings.type = type
                    }
                #endif
                
                // Set the DJI SDK version
                settings.sdkVersion = DJISDKManager.getSDKVersion()
                
                // Set the product firmware version
                settings.firmwareVersion = self.firmwareVersion
                
            }
            
        case "overviewSegue":
            
            if let overview = segue.destinationViewController as? PanoramaViewController {
                overview.panorama = self.currentPanorama
            }
            
        default:
            break;
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        switch identifier {
        case "overviewSegue":
            return self.currentPanorama != nil
        case "cameraSettingsSegue":
            #if DEBUG
                return true
            #else
                return false
                // TODO - when ready: return self.panoramaController?.cameraController != nil
            #endif
        default:
            return true
        }
    }
}

// MARK: - Connection Controller Delegate

extension MainViewController: ConnectionControllerDelegate {
    func sdkRegistered() {
        DDLogInfo("Registered")
    }

    func failedToRegister(reason: String) {
        DDLogWarn("Failed to register \(reason)")

        displayToastOnApp(reason)
    }

    func connectedToProduct(product: DJIBaseProduct) {
        DDLogInfo("New product \(product.model)")

        hideWarning()

        self.product = product

        self.previewController?.setMode(product)

        self.panoramaController?.product = product

        self.resetLabels()

        self.connectionStatusIndicator.image = ConnectionStatusIcon.Connected.image()

        self.startButton.enabled = true

        self.rcInFMode = false
    }

    func disconnected() {
        DDLogInfo("Disconnected")

        self.resetLabels()

        self.connectionStatusIndicator.image = ConnectionStatusIcon.Disconnected.image()
        
        self.startButton.enabled = false

        self.rcInFMode = false

        self.product = nil
        self.batteryController = nil

        self.panoramaController?.setFC(nil)
        self.panoramaController?.setCamera(nil)
        self.panoramaController?.setGimbal(nil)
        self.panoramaController?.setRemote(nil)
    }

    func connectedToBattery(battery: DJIBattery) {
        self.batteryController = BatteryController(battery: battery)
        self.batteryController!.delegate = self
    }

    func disconnectedFromBattery() {
        self.batteryController = nil
    }

    func connectedToCamera(camera: DJICamera) {
        self.panoramaController?.setCamera(camera, preview: self.previewController)
    }

    func disconnectedFromCamera() {
        self.panoramaController?.setCamera(nil)
    }

    func connectedToGimbal(gimbal: DJIGimbal) {
        self.panoramaController?.setGimbal(gimbal)
    }

    func disconnectedFromGimbal() {
        self.panoramaController?.setGimbal(nil)
    }

    func connectedToRemote(remote: DJIRemoteController) {
        self.panoramaController?.setRemote(remote)
    }

    func disconnectedFromRemote() {
        self.panoramaController?.setRemote(nil)
    }

    func connectedToFlightController(flightController: DJIFlightController) {
        self.panoramaController?.setFC(flightController)
    }

    func disconnectedFromFlightController() {
        self.panoramaController?.setFC(nil)
    }
    
    func firmwareVersion(version: String) {
        self.firmwareVersion = version
    }
}

// MARK: - Battery Controller Delegate

extension MainViewController: BatteryControllerDelegate {

    func batteryControllerPercentUpdated(batteryPercent: Int) {
        dispatch_async(dispatch_get_main_queue()) {
            self.setBattery(batteryPercent)
        }

        if (batteryPercent < 10) {
            showWarning("Battery Low: \(batteryPercent)%")
        }
    }

    func batteryControllerTemperatureUpdated(batteryTemperature: Int) {
        // TODO: Battery temperature
    }
}

// MARK: - Panorama Controller Delegate

extension MainViewController: PanoramaControllerDelegate {
    func postUserMessage(message: String) {
        displayToastOnApp(message)
    }

    func postUserWarning(warning: String) {
        showWarning(warning)
    }

    func panoStarting() {
        dispatch_async(dispatch_get_main_queue()) {
            self.currentPanorama = nil
            self.startButton.setBackgroundImage(UIImage(named: "Stop"), forState: .Normal)
            self.panoProgressBar.setProgress(0, animated: false)
            self.resetInfoLabels()
        }

    }

    func panoStopping() {
        dispatch_async(dispatch_get_main_queue()) {
            self.startButton.setBackgroundImage(UIImage(named: "Start"), forState: .Normal)
            self.panoProgressBar.setProgress(0, animated: false)
            self.resetInfoLabels()
        }
    }

    func gimbalAttitudeChanged(pitch pitch: Float, yaw: Float, roll: Float) {
        dispatch_async(dispatch_get_main_queue()) {
            self.gimbalPitchLabel.text = String(format: "Gimbal Pitch: %.1f˚", pitch)
            self.gimbalYawLabel.text = String(format: "Gimbal Yaw: %.1f˚", yaw)
            self.gimbalRollLabel.text = String(format: "Gimbal Roll: %.1f˚", roll)
        }
    }

    func aircraftYawChanged(yaw: Float) {
        dispatch_async(dispatch_get_main_queue()) {
            self.acYawLabel.text = String(format: "Aircraft Yaw: %.1f˚", yaw)
        }
    }

    func aircraftSatellitesChanged(count: Int) {
        dispatch_async(dispatch_get_main_queue()) {
            self.setSatellites(count)
        }
    }

    func aircraftAltitudeChanged(altitude: Float) {
        dispatch_async(dispatch_get_main_queue()) {
            self.setAltitude(Int(altitude))
        }
    }

    func aircraftDistanceChanged(distance: CLLocationDistance) {
        dispatch_async(dispatch_get_main_queue()) {
            self.setDistance(Int(distance))
        }
    }

    func panoCountChanged(count: Int, total: Int) {
        dispatch_async(dispatch_get_main_queue()) {
            self.setSequence(count, count: total)
        }
    }

    func panoAvailable(available: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            self.startButton.enabled = available
        }
    }
    
    func panoCompleted(panorama: Panorama) {
        dispatch_async(dispatch_get_main_queue()) {
            self.currentPanorama = panorama
            
            self.performSegueWithIdentifier("overviewSegue", sender: self)
        }
    }
}

// MARK: - Panorama Camera Controls Delegate

extension MainViewController: PanoramaCameraControlsDelegate {
    func cameraExposureModeUpdated(mode: DJICameraExposureMode) {
        dispatch_async(dispatch_get_main_queue()) {
            self.setCameraMode(mode)
        }
    }
    
    func cameraISOUpdated(ISO: UInt) {
        dispatch_async(dispatch_get_main_queue()) {
            self.setCameraISO(DJICameraISO(rawValue: ISO))
        }
    }
    
    func cameraApertureUpdated(aperture: DJICameraAperture) {
        dispatch_async(dispatch_get_main_queue()) {
            self.setCameraAperture(aperture)
        }
    }
    
    func cameraShutterSpeedUpdated(shutterSpeed: DJICameraShutterSpeed) {
        dispatch_async(dispatch_get_main_queue()) {
            self.setCameraSpeed(shutterSpeed)
        }
    }
    
    func cameraExposureCompensationUpdated(comp: DJICameraExposureCompensation) {
        dispatch_async(dispatch_get_main_queue()) {
            self.setCameraExposureCompensation(comp)
        }
    }
}

extension MainViewController : UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        if (traitCollection.horizontalSizeClass == .Regular && traitCollection.verticalSizeClass == .Regular) {
            // Large enough - don't adapt
            return .None
        } else {
            // Too small - go full screen
            return .OverFullScreen
        }
    }
}
