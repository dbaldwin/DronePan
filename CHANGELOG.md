# Change Log

## [1.6b16](https://github.com/dbaldwin/DronePan/releases/tag/1.6b16)

* Updated UI with icons and connection status light
* View camera settings: mode, aperture, shutter, ISO, exposure compensation
* Better debug logging with papertrail
* Updated video previewer from SDK 3.3
* Video preview now full screen

## 1.5

#### App Issues

* Video feed doesn't fill the view in all cases [Issue 33](https://github.com/dbaldwin/DronePan/issues/33)
* Gimbal yaw for I1 coming soon [Issue 24](https://github.com/dbaldwin/DronePan/issues/24)

### [1.5b14](https://github.com/dbaldwin/DronePan/releases/tag/1.5b14)

* Added DJI SDK 3.3 which comes with support for Osmo Mobile
* Enabled pitch range extension for Phantom users. This should force the +30 sky row if it's selected in DronePan (it is by default) and not enabled in GO.

## 1.4.3

### Known issues

#### DJI Issues

SDK 3.2 does not tell us when a photo or video is taken the first time after the SD card is formatted. DJI
have said that this will be fixed in a later version of the SDK. Please make sure that after formatting you
have taken at least one photo or video before running DronePan.

### [1.4.3b13](https://github.com/dbaldwin/DronePan/releases/tag/1.4.3b13)

* Added sdk version and firmware version to settings screen for debug purposes.
* Notify P4 users if they try to shoot a pano when not in P mode
* AEB photo option in settings

### [1.4.3b12](https://github.com/dbaldwin/DronePan/releases/tag/1.4.3b12)

Added sdk version and firmware version to settings screen for debug purposes.

### [1.4.3b11](https://github.com/dbaldwin/DronePan/releases/tag/1.4.3b11)

An incremental build to extend the TestFlight beta.

### [1.4.3b10](https://github.com/dbaldwin/DronePan/releases/tag/1.4.3b10)

#### Sky Row -> Max Pitch

##### Sky Row

A normal drone panorama with DronePan runs from a start pitch of 0˚ down to the nadir at -90˚.

Originally we supported only 0˚, -30˚, -60˚ then the nadir at -90˚.

But the Inspire 1 allows you to point above the horizon - to a maximum pitch of +30˚. So we added a “Sky Row” concept that meant “if you choose sky row then we’ll add a row at +30˚”.

##### Max Pitch

But here’s the issue with that - we also added the ability to add more rows. And so - you can get more rows in the 30˚-0˚ than just one.

So - this is a change - we’re removing “Sky Row” - and adding instead “Max Pitch” if the gimbal we see tells us it can go above 0˚.

You can therefore choose the max pitch (for all known DJI drones right now that’s a +30˚ setting) or “Horizon”.

It won’t automatically add an extra row - you can set whatever row count you want and that will be the row count instead of having to remember “oh - I chose sky row - that means it’s this number + 1”.

##### Notes

* Osmo - we will always use Max Pitch. For the Osmo - positive pitch is down instead of up (DJI basically took the I1 gimbal and turned it upside-down). But this setting will always be used and does not appear on the settings page
* Phantom models - these require a setting in DJI Go to be allowed to go above the horizon. You may be able to set that setting and test if you can set a Max Pitch. I don’t have a Phantom to test with - so I can’t tell if it will work or not. There is a new setting in the latest SDK which talks about pitch extension - we’re going to look at that - but haven’t got there yet - see [Issue #53](https://github.com/dbaldwin/DronePan/issues/53).

#### Updates

* Settings window will now only show relevant options - start delay for Osmo only, max pitch for aircraft (that support it) only (Osmo will always choose the extended range).
* Settings window - show the pitch angle as well as the yaw angle for the current settings.
* If you choose a combination of row count and max pitch that gives a pitch angle more than 30˚ it will allow it but will show the angle in red - you may wish to consider fewer rows or not enabling max pitch in this situation.
* Choose how many nadir/zenith shots

#### Fixes

* When we work out the row pitch angles - it was always doing a 30 degree change between 60 down and straight down - causing stitching issues for X5 users towards the bottom of the pano image. Fixed!
* Keep logs for up to 5 days instead of just 24 hours
* Gimbal reset at start back in place for I1 and P4

### [1.4.3b9](https://github.com/dbaldwin/DronePan/releases/tag/1.4.3b9)

1.4.3b9 was only released to internal testers.

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

