#!/bin/sh

xctool -scheme DronePan clean build test -sdk iphonesimulator9.3 -destination 'platform=iOS Simulator,name=iPhone 6,OS=9.3' GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES GCC_GENERATE_TEST_COVERAGE_FILES=YES