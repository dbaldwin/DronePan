# Change Log

## 1.4.3

### Known issues


#### DJI Issues

SDK 3.2 does not tell us when a photo or video is taken the first time after the SD card is formatted. DJI
have said that this will be fixed in a later version of the SDK. Please make sure that after formatting you
have taken at least one photo or video before running DronePan.

#### App Issues

* Video feed doesn't fill the view in all cases [Issue 33](https://github.com/dbaldwin/DronePan/issues/33)
* Gimbal yaw for I1 coming soon [Issue 24](https://github.com/dbaldwin/DronePan/issues/24)
* Gimbal yaw reset for P4 and I1 is currently disabled - you will have to make sure the gimbal is pointing forwards yourself [Issue 48](https://github.com/dbaldwin/DronePan/issues/48)

### [1.4.3b9](https://github.com/dbaldwin/DronePan/releases/tag/1.4.3b9)

#### Updates

* Distances (distance/altitude) in metric or imperial units - toggle under settings
* Updated launch screen

#### Fixes

* Possible crash in gimbal handling

### [1.4.3b8](https://github.com/dbaldwin/DronePan/releases/tag/1.4.3b8)

#### Updates

* Add low battery warning
* Add ability to keep info window present at all times (iOS System Settings App > DronePan)
* Implement new DJI SDK method - hopefully will make detection of camera/gimbal/etc more reliable
* Add a thin progress bar
* Move settings from segment to slider to allow for finer user control
* Increase max number of rows to 10
* Opt-in analytics. You'll be asked at start and can always change your mind later (iOS System Settings App > DronePan)

## 1.4.2 released

1.4.2b4 was released as 1.4.2 to the App Store

### [1.4.2b4](https://github.com/dbaldwin/DronePan/releases/tag/1.4.2b4)

#### Updates

* Update to DJI SDK 3.2
* Update to latest Video Previewer
* Use hardware decoding for Video Previewer when the connected model supports it
* Small info window (bottom left) while capturing to show current values of yaw/pitch/roll
* Allow access to settings window when disconnected to get version and copy to log functionality

### [1.4.2b3](https://github.com/dbaldwin/DronePan/releases/tag/1.4.2b3)

#### Updates

* Allow setting number of rows via settings
* Check that the card has space for the pano before starting
* Check flight mode is F before starting for P3 and I1
* Add ability to copy current log to clipboard from settings
* Some text label updates in settings to make things clearer

#### Fixes

* Fix handling of change in camera state so that we don't forget to re-enable start button
* Fix (hopefully) the reset gimbal error by moving to the reset position with normal move instead of reset
* Don't allow sky row for Phantom models - they don't support +30 via the SDK.

### [1.4.2b2](https://github.com/dbaldwin/DronePan/releases/tag/1.4.2b2)

#### Fixes

* Fix yaw past 180 for Osmo

### [1.4.2b1](https://github.com/dbaldwin/DronePan/releases/tag/1.4.2b1)

#### Updates

* Update to DJI SDK 3.1
* Faster - we now react to the device saying "finished" instead of waiting long enough that we think it worked - so panoramas should go faster
* More stable - since we actually check for move completion and camera shot saved to disk - we should finally be **over the missing shot bug** - in fact it'll retry up to 5 times for each move and photo
* Osmo support
* Phantom 4 support
* Delay on start (Osmo) - your "get out of shot" time
* Choose number of photos in row
* Choose extra sky row (point the gimbal up to 30˚) - aircraft only (Osmo will always do it's full gimbal pitch)

