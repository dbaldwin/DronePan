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

@objc protocol ConnectionControllerDelegate {
    func registered()
    func failedToRegister(reason: String)
    
    func connectedToProduct(product: DJIBaseProduct)
    func disconnected()
    
    func connectedToBattery(battery: DJIBattery)
    func connectedToCamera(camera: DJICamera)
    func connectedToGimbal(gimbal: DJIGimbal)
    func connectedToRemote(remote: DJIRemoteController)
    func connectedToFlightController(flightController: DJIFlightController)

    func disconnectedFromBattery()
    func disconnectedFromCamera()
    func disconnectedFromGimbal()
    func disconnectedFromRemote()
    func disconnectedFromFlightController()
}

@objc class ConnectionController: NSObject, DJISDKManagerDelegate, DJIBaseProductDelegate {
    let connectToSimulator = false
    let bridgeAddress = "10.0.1.18"
    
    let appKey = "d6b78c9337f72fadd85d88e2"
    
    var delegate : ConnectionControllerDelegate?
    
    var model : String?
    
    func start() {
        DJISDKManager.registerApp(appKey, withDelegate: self)
    }
    
    func sdkManagerDidRegisterAppWithError(error: NSError?) {
        if let error = error {
            DDLogWarn("Registration failed with \(error)")
            
            self.delegate?.failedToRegister(error.description)
        } else {
            DDLogDebug("Connecting to product")
            
            if (connectToSimulator) {
                DDLogDebug("Connecting to debug bridge")
                DJISDKManager.enterDebugModeWithDebugId(bridgeAddress)
            } else {
                DDLogDebug("Connecting to real product")
                DJISDKManager.startConnectionToProduct()
            }
        }
    }
    
    func sdkManagerProductDidChangeFrom(oldProduct: DJIBaseProduct?, to newProduct: DJIBaseProduct?) {
        self.model = newProduct?.model

        if let product = newProduct {
            DDLogInfo("Connected to \(self.model)")
            product.delegate = self
            self.delegate?.connectedToProduct(product)

            if let components = product.components {
                for (key, component) in components {
                    for c in component {
                        self.componentWithKey(key, changedFrom: nil, to: c)
                    }
                }
            }
        } else {
            DDLogInfo("Disconnected")
            self.delegate?.disconnected()
        }
    }
    
    func product(product: DJIBaseProduct, didUpdateDiagnosticsInformation info: [AnyObject]) {
        for diagnostic in info {
            if let d = diagnostic as? DJIDiagnostics {
                DDLogDebug("Diagnostic for \(model): Code: \(d.code), Reason: \(d.reason), Solution: \(d.solution)")
            }
        }
    }

    func componentWithKey(key: String, changedFrom oldComponent: DJIBaseComponent?, to newComponent: DJIBaseComponent?) {
        switch key {
        case DJIBatteryComponentKey:
            if let battery = newComponent as? DJIBattery {
                DDLogDebug("New battery")
                self.delegate?.connectedToBattery(battery)
            } else {
                DDLogDebug("No battery")
                self.delegate?.disconnectedFromBattery()
            }
        case DJICameraComponentKey:
            if let camera = newComponent as? DJICamera {
                DDLogDebug("New camera")
                self.delegate?.connectedToCamera(camera)
            } else {
                DDLogDebug("No camera")
                self.delegate?.disconnectedFromCamera()
            }
        case DJIGimbalComponentKey:
            if let gimbal = newComponent as? DJIGimbal {
                DDLogDebug("New gimbal")
                self.delegate?.connectedToGimbal(gimbal)
            } else {
                DDLogDebug("No gimbal")
                self.delegate?.disconnectedFromGimbal()
            }
        case DJIRemoteControllerComponentKey:
            if let remote = newComponent as? DJIRemoteController {
                DDLogDebug("New remote")
                self.delegate?.connectedToRemote(remote)
            } else {
                DDLogDebug("No remote")
                self.delegate?.disconnectedFromRemote()
            }
        case DJIFlightControllerComponentKey:
            if let fc = newComponent as? DJIFlightController {
                DDLogDebug("New flight controller")
                self.delegate?.connectedToFlightController(fc)
            } else {
                DDLogDebug("No flight controller")
                self.delegate?.disconnectedFromFlightController()
            }
        default:
            DDLogDebug("Not handling \(key)")
        }
    }
}