[![Join the chat at https://gitter.im/dbaldwin/DronePan](https://badges.gitter.im/dbaldwin/DronePan.svg)](https://gitter.im/dbaldwin/DronePan?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Build Status](https://travis-ci.org/dbaldwin/DronePan.svg?branch=master)](https://travis-ci.org/dbaldwin/DronePan)
[![codecov](https://codecov.io/gh/dbaldwin/DronePan/branch/master/graph/badge.svg)](https://codecov.io/gh/dbaldwin/DronePan)

# DronePan

DronePan - 360 aerial panoramas with DJI Inspire 1 and Phantom 3 drones.

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

Apart from XCode we're using [Carthage](https://github.com/Carthage/Carthage) to handle dependencies.

After cloning - you'll need to run

    carthage bootstrap

