XCODEGEN := xcodegen
PROJECT  := OnAir.xcodeproj
SCHEME   := OnAir

.PHONY: all generate open build release clean

all: build

generate:
	$(XCODEGEN) generate

open: generate
	open $(PROJECT)

build: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release build

# Ad-hoc signed build for distribution outside the App Store, without a paid
# Apple Developer account. Gatekeeper will still warn on first launch since
# there's no Developer ID; see README for the workaround. Mirrors the build
# GitHub Actions runs for tagged releases.
release: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release \
		-derivedDataPath build \
		CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="-" \
		CODE_SIGNING_REQUIRED=YES CODE_SIGNING_ALLOWED=YES DEVELOPMENT_TEAM="" \
		build
	rm -f OnAir.zip
	cd build/Build/Products/Release && zip -r $(CURDIR)/OnAir.zip OnAir.app

clean:
	rm -rf $(PROJECT) build DerivedData Config/Info.plist OnAir.zip
