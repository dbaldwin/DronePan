# Change Log

## 1.4.2

### Known issues

* Video feed doesn't fill the view in all cases [Issue 33](https://github.com/dbaldwin/DronePan/issues/33)
* Gimbal yaw for I1 coming soon [Issue 24](https://github.com/dbaldwin/DronePan/issues/24)

### [1.4.2b3](https://github.com/dbaldwin/DronePan/releases/tag/1.4.2b3)

#### Updates

* Allow setting number of rows via settings
* Check that the card has space for the pano before starting
* Check flight mode is F before starting
* Add ability to copy current log to clipboard from settings
* Some text label updates in settings to make things clearer

#### Fixes

* Fix handling of change in camera state so that we don't forget to re-enabled start button
* Fix (hopefully) the reset gimbal error by moving to the reset position with normal move instead of reset
* Don't allow sky row for Phantom 3 - it doesn't support +30 via the SDK.

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

