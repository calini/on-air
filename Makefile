XCODEGEN := xcodegen
PROJECT  := OnAir.xcodeproj
SCHEME   := OnAir

.PHONY: all generate open build clean

all: build

generate:
	$(XCODEGEN) generate

open: generate
	open $(PROJECT)

build: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release build

clean:
	rm -rf $(PROJECT) build DerivedData Config/Info.plist
