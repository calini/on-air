XCODEGEN := xcodegen
PROJECT  := OnAir.xcodeproj
SCHEME   := OnAir

ICONSET := build/AppIcon.iconset

.PHONY: all generate icon open build release clean

all: build

generate:
	$(XCODEGEN) generate

# Regenerates Resources/AppIcon.icns from icon.png. Run by hand whenever
# icon.png changes; the .icns is committed like any other resource, not
# regenerated on every build.
icon:
	rm -rf $(ICONSET)
	mkdir -p $(ICONSET)
	sips -z 16 16     icon.png --out $(ICONSET)/icon_16x16.png
	sips -z 32 32     icon.png --out $(ICONSET)/icon_16x16@2x.png
	sips -z 32 32     icon.png --out $(ICONSET)/icon_32x32.png
	sips -z 64 64     icon.png --out $(ICONSET)/icon_32x32@2x.png
	sips -z 128 128   icon.png --out $(ICONSET)/icon_128x128.png
	sips -z 256 256   icon.png --out $(ICONSET)/icon_128x128@2x.png
	sips -z 256 256   icon.png --out $(ICONSET)/icon_256x256.png
	sips -z 512 512   icon.png --out $(ICONSET)/icon_256x256@2x.png
	sips -z 512 512   icon.png --out $(ICONSET)/icon_512x512.png
	sips -z 1024 1024 icon.png --out $(ICONSET)/icon_512x512@2x.png
	mkdir -p Resources
	iconutil -c icns $(ICONSET) -o Resources/AppIcon.icns
	rm -rf $(ICONSET)

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
