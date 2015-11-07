//
//  CraftCommandCenter.swift
//  DronePan
//
//  Created by V Mahadev on 07/11/15.
//  Copyright © 2015 Unmanned Airlines, LLC. All rights reserved.
//

import Foundation


class CraftCommandCenter{
    var _drone:DJIDrone
    var _gimbal:DJIGimbal
    var _camera:DJICamera
    var _mInspireMainController:DJIMainController
    var _droneType:DJIDroneType
    var _droneDelegateHandler:DroneDelegateHandler
    var _yawMode:YawMode
    
    init(droneType:DJIDroneType){
        
         _droneDelegateHandler=DroneDelegateHandler()
        
        _droneType=droneType
        
        _drone=DJIDrone(type: droneType)
        
        _gimbal=_drone.gimbal
        
        _gimbal.delegate=_droneDelegateHandler
        
        _camera=_drone.camera
        _camera.delegate=_droneDelegateHandler
        
        _mInspireMainController=_drone.mainController
        
        _yawMode=Gimbal
        
    }

    
}