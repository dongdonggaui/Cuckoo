.PHONY: dev

dev: generator-xcodeproj
	tuist generate -n
	# Use Bundler if available, otherwise just call system-wide CocoaPods.
	if ! command -v bundle &> /dev/null; then bundle install && bundle exec pod install; else pod install; fi
	xed Cuckoo.xcworkspace

generator-xcodeproj:
	cd Generator && swift package generate-xcodeproj --output ./CuckooGenerator.xcodeproj
