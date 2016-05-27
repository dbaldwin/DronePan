.PHONY: clean build test

clean:
	xcodebuild -scheme DronePan -sdk iphonesimulator9.3 -destination "platform=iOS Simulator,name=iPhone 6,OS=9.3" clean

build:
	xcodebuild -scheme DronePan -sdk iphonesimulator9.3 -destination "platform=iOS Simulator,name=iPhone 6,OS=9.3" build

test:
	xcodebuild -scheme DronePan -sdk iphonesimulator9.3 -destination "platform=iOS Simulator,name=iPhone 6,OS=9.3" -enableCodeCoverage YES test | xcpretty

coverage:
	scripts/coverage.sh
