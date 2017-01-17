[![Join the chat at https://gitter.im/dbaldwin/DronePan](https://img.shields.io/gitter/room/dbaldwin/DronePan.svg)](https://gitter.im/dbaldwin/DronePan?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Build Status](https://img.shields.io/travis/dbaldwin/DronePan.svg)](https://travis-ci.org/dbaldwin/DronePan)
[![codecov](https://img.shields.io/codecov/c/github/dbaldwin/DronePan.svg)](https://codecov.io/gh/dbaldwin/DronePan)
![Tag](https://img.shields.io/github/tag/dbaldwin/DronePan.svg)
[![Issues](https://img.shields.io/github/issues/dbaldwin/DronePan.svg)](https://github.com/dbaldwin/DronePan/issues)
[![GPLv3](https://img.shields.io/github/license/dbaldwin/DronePan.svg)](https://github.com/dbaldwin/DronePan/blob/master/LICENSE.md)

# DronePan

DronePan - 360 aerial panoramas with DJI (Phantom (3 and later), Inspire, Matrice, Mavic, Osmo family)

[![Download on the App Store](https://linkmaker.itunes.apple.com/images/badges/en-us/badge_appstore-lrg.svg)](https://itunes.apple.com/us/app/dronepan/id1026329337?mt=8)

As of 6th March 2016 DronePan is open source.

* For bugs, feature requests etc - please use the project issues page.

## Want to help out?

If you want to help out then there are several things you can do:

* Come talk to us on [gitter.im](https://gitter.im/dbaldwin/DronePan)
* Fork the project and send in pull requests
* Create issues if you have a problem/bug or suggestion

## Want to beta test?

For iOS we use TestFlight from Apple. To sign up - please fill out [the following form](http://visitor.r20.constantcontact.com/manage/optin?v=001giAVbUCFt6Z0lHA2j823X8YlGHySkIZU2_0-gjeim4o4r4T2WGHTGBXU4zPH3taTcbW4D7ZXjegaGxWjFTGBiHPwQmf-lVHqhEoKeJ6z_8Mopf-pVV7ruoyBe8eHKJwNlYnWehVqt8uJqkNbAXYLp0fArIx4SJrj)

### It's not working!?!?!

OK - that's not good. And we'd like to help.

But! We do need to know what's not working.

Some basic info we need:

* What actually happened? "It didn't work" doesn't give us a lot to go on
* What version of DronePan are you running - see Settings (lower right corner)
* What DJI device are you running and which firmware is it on
* What does the DronePan log say - see Settings > Copy log to clipboard (lower left corner)

It's best to grab a copy of that log right after it didn't work. We don't want to use up a lot of space on your device so it won't hang around for too long.

## Facebook

Join our Facebook group here: http://www.facebook.com/groups/dronepan

## Development

Tools in use:

* XCode (surprise)
* [Carthage](https://github.com/Carthage/Carthage) to handle dependencies
* git-lfs because the DJI SDK is too large for the repo on github

To clone - make sure you have git-lfs installed _before_ you clone.

This is easiest with homebrew:

    brew install git git-lfs

Your clone command will look like this:

    git lfs clone https://github.com/dbaldwin/DronePan

After cloning - you'll need to run:

    carthage bootstrap --platform ios
