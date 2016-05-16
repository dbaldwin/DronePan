#!/bin/sh

xcodebuild -scheme DronePan -sdk iphonesimulator9.3 -destination "platform=iOS Simulator,name=iPhone 6,OS=9.3" -enableCodeCoverage YES test
