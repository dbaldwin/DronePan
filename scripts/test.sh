#!/bin/sh

xcodebuild -scheme DronePan -sdk iphonesimulator9.3 -destination "platform=iOS Simulator,name=iPhone 6,OS=9.3" build test GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES GCC_GENERATE_TEST_COVERAGE_FILES=YES