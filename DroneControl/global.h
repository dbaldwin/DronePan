//
//  global.h
//  DronePan
//
//  Created by V Mahadev on 06/11/15.
//  Copyright © 2015 Unmanned Airlines, LLC. All rights reserved.
//

#ifndef global_h
#define global_h

// Command Center



enum _CommandResponseStatus{
    failure,
    error,
    success
};

typedef enum _CommandResponseStatus CommandResponseStatus;

enum _NoteType{
    CmdCenter_DroneChanged=0,
    CmdCenter_DroneNotConnected,
    CmdCenter_DroneConnected,
    CmdCenter_CmdExecInProgress,
    CmdCenter_CmdSuccess,
    CmdCenter_CmdFailed,
    CmdCenter_CmdError
};

typedef enum _NoteType NoteType;

enum _DroneDirectionType{
    
    DroneDirectionAbsolute=0,
    DroneDirectionNorth,
    DroneDirectionEast,
    DroneDirectionSouth,
    DroneDirectionWest,
    DroneDirectionNorthWest,
    DroneDirectionNorthEast,
    DroneDirectionSouthEast,
    DroneDirectionSouthWest,
    
};

typedef enum _DroneDirectionType DroneDirection;


#endif /* global_h */
