#!/bin/sh

set -o pipefail && xcodebuild -scheme DronePan -sdk iphonesimulator9.3 -destination 'platform=iOS Simulator,name=iPhone 6,OS=9.3' clean build GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES GCC_GENERATE_TEST_COVERAGE_FILES=YES | xcpretty
sleep 10
set -o pipefail && xcodebuild -scheme DronePan -sdk iphonesimulator9.3 -destination 'platform=iOS Simulator,name=iPhone 6,OS=9.3' test GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES GCC_GENERATE_TEST_COVERAGE_FILES=YES | xcpretty
#sleep 10
#set -o pipefail && xcodebuild -scheme DronePanUITests -sdk iphonesimulator9.3 -destination 'platform=iOS Simulator,name=iPhone 6,OS=9.3' test GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES GCC_GENERATE_TEST_COVERAGE_FILES=YES | xcpretty
