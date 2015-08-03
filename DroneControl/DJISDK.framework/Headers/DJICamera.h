//
//  DJICamera.h
//  DJISDK
//
//  Copyright (c) 2015 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <DJISDK/DJISDCardOperation.h>
#import <DJISDK/DJIObject.h>
#import <DJISDK/DJICameraSettingsDef.h>

@class DJIMedia;
@class DJICamera;
@class DJICameraSystemState;
@class DJICameraPlaybackState;

@protocol DJICameraDelegate <NSObject>

@required
/**
 *  Video data interface
 *
 *  @param videoBuffer H.264 video data buffer
 *  @param length      H.264 video data length
 */
-(void) camera:(DJICamera*)camera didReceivedVideoData:(uint8_t*)videoBuffer length:(int)length;

/**
 *  Update the camera's system state. User should call the startCameraSystemStateUpdates
 *  interface to begin updating.
 *
 *  @param systemState The camera's system state.
 */
-(void) camera:(DJICamera*)camera didUpdateSystemState:(DJICameraSystemState*)systemState;

@optional
/**
 *  Push media info while completed taking photo or recording.
 *
 *  @param newMedia The new media object.
 */
-(void) camera:(DJICamera *)camera didGeneratedNewMedia:(DJIMedia*)newMedia;

/**
 *  Update playback state. only supported in inspire camera.
 *
 *  @param playbackState The camera's playback state.
 */
-(void) camera:(DJICamera *)camera didUpdatePlaybackState:(DJICameraPlaybackState*)playbackState;

@end

@interface DJICamera : DJIObject<DJISDCardOperation>

@property(nonatomic, weak) id<DJICameraDelegate> delegate;

/**
 *  Get the camera's firmware version
 *
 *  @return Return the firmware version of the camera. return nil if disconnected.
 */
-(NSString*) getCameraVersion;

/**
 *  Take photo with mode, if the capture mode is CameraMultiCapture or CameraContinousCapture, you should call stopTakePhotoWithResult to stop photoing
 *
 *  @param captureMode Tell the camera what capture action will be do, if capture mode is multi capture or continuous capture, user should call the 'stopTakePhotWithResult' to stop catpture if need.
 *  @param block  The remote execute result.
 */
-(void) startTakePhoto:(CameraCaptureMode)captureMode withResult:(DJIExecuteResultBlock)block;

/**
 *  Stop the mutil capture or continous capture. should match the startTakePhoto action.
 *
 *  @param block       The remote execute result
 */
-(void) stopTakePhotoWithResult:(DJIExecuteResultBlock)block;

/**
 *  Start recording
 *
 *  @param block The remote execute result
 */
-(void) startRecord:(DJIExecuteResultBlock)block;

/**
 *  Stop recording
 *
 *  @param block The remote execute result
 */
-(void) stopRecord:(DJIExecuteResultBlock)block;

/**
 *  Start the system state updates.
 */
-(void) startCameraSystemStateUpdates;

/**
 *  Stop the system state updates
 */
-(void) stopCameraSystemStateUpdates;

@end

@interface DJICamera (CameraSettings)

/**
 *  Set the video quality, e.g. 640x480
 *
 *  @param videoQuality Video quality to be set
 *  @param block  The remote execute result
 *  @attention If the parameters was configured successed, the remote video module will restart
 */
-(void) setVideoQuality:(VideoQuality)videoQuality withResultBlock:(DJIExecuteResultBlock)block;

/**
 *  Set the photo's pixel size
 *
 *  @param photoSize Photo's pixel size
 *  @param block     The remote execute result block
 */
-(void) setCameraPhotoSize:(CameraPhotoSizeType)photoSize withResultBlock:(DJIExecuteResultBlock)block;

/**
 *  Get the photo's pixel size
 *
 *  @param block The remote execute result block
 */
-(void) getCameraPhotoSize:(void (^)(CameraPhotoSizeType photoSize, DJIError* error))block;

/**
 *  Set camera's ISO
 *
 *  @param isoType Iso type
 *  @param block   The remote execute result block
 */
-(void) setCameraISO:(CameraISOType)isoType withResultBlock:(DJIExecuteResultBlock)block;

/**
 *  Get the camera's ISO
 *
 *  @param block The remote execute result block
 */
-(void) getCameraISO:(void (^)(CameraISOType iso, DJIError* error))block;

/**
 *  Set the camera's white balance
 *
 *  @param whiteBalance White balance
 *  @param block        The remote execute result block
 */
-(void) setCameraWhiteBalance:(CameraWhiteBalanceType)whiteBalance withResultBlock:(DJIExecuteResultBlock)block;

/**
 *  Get the camera's white balance
 *
 *  @param block The remote execute result block
 */
-(void) getCameraWhiteBalance:(void (^)(CameraWhiteBalanceType whiteBalance, DJIError* error))block;

/**
 *  Set the camera's exposure metering parameter
 *
 *  @param meteringType exposure metering
 *  @param block        The remote execute result block
 */
-(void) setCameraExposureMetering:(CameraExposureMeteringType)meteringType withResultBlock:(DJIExecuteResultBlock)block;

/**
 *  Get the camera's exposure metering parameter
 *
 *  @param block The remote execute result block
 */
-(void) getCameraExposureMetering:(void (^)(CameraExposureMeteringType exposureMetering, DJIError* error))block;

/**
 *  Set the camera's recording resolution and fov parameter
 *
 *  @param resolution Recording resolution
 *  @param fov        Recording FOV
 *  @param block      The remote execute result block
 */
-(void) setCameraRecordingResolution:(CameraRecordingResolutionType)resolution andFOV:(CameraRecordingFovType)fov withResultBlock:(DJIExecuteResultBlock)block;

/**
 *  Get the camera's recording resolution and fov parameter
 *
 *  @param block The remote execute result block
 */
-(void) getCameraRecordingResolution:(void (^)(CameraRecordingResolutionType resolution, CameraRecordingFovType fov, DJIError* error))block;

/**
 *  Set the camera's photo storage format
 *
 *  @param photoFormat Photo storage formate
 *  @param block       The remote execute result block
 */
-(void) setCameraPhotoFormat:(CameraPhotoFormatType)photoFormat withResultBlock:(DJIExecuteResultBlock)block;

/**
 *  Get the camera's photo storage format
 *
 *  @param block The remote execute result block
 */
-(void) getCameraPhotoFormat:(void(^)(CameraPhotoFormatType photoFormat, DJIError* error))block;

/**
 *  Set the camera's exposure compensation
 *
 *  @param compensationType
 *  @param block            The remote execute result block
 */
-(void) setCameraExposureCompensation:(CameraExposureCompensationType)compensationType withResultBlock:(DJIExecuteResultBlock)block;

/**
 *  Get camera's exposure compensation
 *
 *  @param block The remote execute result block
 */
-(void) getCameraExposureCompensation:(void (^)(CameraExposureCompensationType exposureCompensation, DJIError* error))block;

/**
 *  Set the camera's anti flicker parameter
 *
 *  @param antiFlickerType Anti flicker type
 *  @param block           The remote execute result block
 */
-(void) setCameraAntiFlicker:(CameraAntiFlickerType)antiFlickerType withResultBlock:(DJIExecuteResultBlock)block;

/**
 *  Get the camera's anti flicker parameter
 *
 *  @param block The remote execute result block
 */
-(void) getCameraAntiFlicker:(void (^)(CameraAntiFlickerType antiFlicker, DJIError* error))block;

/**
 *  Set the camera's sharpness parameter
 *
 *  @param sharpness Sharpness
 *  @param block     The remote execute result block
 */
-(void) setCameraSharpness:(CameraSharpnessType)sharpness withResultBlock:(DJIExecuteResultBlock)block;

/**
 *  Get camera sharpness parameter
 *
 *  @param block The remote execute result block
 */
-(void) getCameraSharpness:(void (^)(CameraSharpnessType sharpness, DJIError* error))block;

/**
 *  Set the camera's contrast parameter
 *
 *  @param contrast Contrast
 *  @param block    The remote execute result block
 */
-(void) setCameraContrast:(CameraContrastType)contrast withResultBlock:(DJIExecuteResultBlock)block;

/**
 *  Get camera contrast
 *
 *  @param block The remote execute result block
 */
-(void) getCameraContrast:(void(^)(CameraContrastType contrast, DJIError* error))block;

/**
 *  Sync local time to camera. the camera should had synced time from device while doing take photo or record action, or the camera will return "Time Not Sync" error
 *
 *  @param block The remote execute result block
 */
-(void) syncTime:(DJIExecuteResultBlock)block;

/**
 *  Set the camera's GPS parameter
 *
 *  @param gps   GPS
 *  @param block The remote execute result block
 */
-(void) setCameraGps:(CLLocationCoordinate2D)gps withResultBlock:(DJIExecuteResultBlock)block;

/**
 *  Get the camera's GPS
 *
 *  @param block The remote execute result block
 */
-(void) getCameraGps:(void (^)(CLLocationCoordinate2D coordinate, DJIError* error))block;

/**
 *  Set multi capture times
 *
 *  @param count Multi capture count
 *  @param block The remote execute result block
 */
-(void) setMultiCaptureCount:(CameraMultiCaptureCount)count withResultBlock:(DJIExecuteResultBlock)block;

/**
 *  Get multi capture count
 *
 *  @param block The remote execute result block
 */
-(void) getMultiCaptureCount:(void(^)(CameraMultiCaptureCount multiCaptureCount, DJIError* error))block;

/**
 *  Set the camera's continuous capture parameters
 *
 *  @param block    The remote execute result block
 */
-(void) setContinuousCapture:(CameraContinuousCapturePara)capturePara withResultBlock:(DJIExecuteResultBlock)block;

/**
 *  Get the camera's continuous capture parameters
 *
 *  @param block The remote execute result block
 */
-(void) getContinuousCaptureParam:(void(^)(CameraContinuousCapturePara capturePara, DJIError* error))block;

/**
 *  Set the camera action mode while the connection was broken.
 *
 *  @param action Camera action
 *  @param block  The remote execute result block
 */
-(void) setCameraActionWhenConnectionBroken:(CameraActionWhenBreak)action withResultBlock:(DJIExecuteResultBlock)block;

/**
 *  Get the camera's action settings while the connection was broken.
 *
 *  @param block The remote execute result block
 */
-(void) getCameraActionWhenConnectionBroken:(void(^)(CameraActionWhenBreak cameraAction, DJIError* error))block;

/**
 *  Save the camera's settings permanently. or the settings will be lost after camera restart.
 *
 *  @param block The remote execute result block
 */
-(void) saveCameraSettings:(DJIExecuteResultBlock)block;

/**
 *  Restore the default settings.
 *
 *  @param block The remote execute result block
 */
-(void) restoreCameraDefaultSettings:(DJIExecuteResultBlock)block;

/**
 *  Set the camera's mode.
 *
 *  @param mode  Camera mode
 *  @param block The remote execute result block
 */
-(void) setCamerMode:(CameraMode)mode withResultBlock:(DJIExecuteResultBlock)block;

/**
 *  Get the camera's photo name prefix
 *
 *  @param block The remote execute result block
 */
-(void) getCameraPhotoNamePrefix:(void (^)(NSString* prefix, DJIError* error))block;

/**
 *  Set the camera's photo name prefix. The new name prefix must have four fixed characters, and the character should be 'A' - 'Z' and '_'
 *
 *  @param prefix Photo name prefix
 *  @param block The remote execute result block
 */
-(void) setCameraPhotoNamePrefix:(NSString*)prefix withResultBlock:(DJIExecuteResultBlock)block;

@end

@interface DJICamera (Media)

/**
 *  Fetch media list from remote album.
 *
 *  @param block The remote execute result block
 *  @attention The camera mode should be set as 'CameraUSBMode'.
 */
-(void) fetchMediaListWithResultBlock:(void(^)(NSArray* mediaList, NSError* error))block;

@end
