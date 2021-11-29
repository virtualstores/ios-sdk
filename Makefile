build: 
	swift build
	
test:
	swift test

lint:
	swiftlint --strict

fixlint: 
	swiftlint --fix

doc: 
	jazzy -c