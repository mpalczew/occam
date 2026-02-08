APP_NAME    := Occam
BUILD_DIR   := .build
APP_BUNDLE  := $(BUILD_DIR)/$(APP_NAME).app
CONTENTS    := $(APP_BUNDLE)/Contents
MACOS_DIR   := $(CONTENTS)/MacOS
VERSION     := $(shell /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)

.PHONY: build build-universal run clean release-universal screenshot

build:
	swift build -c release
	mkdir -p $(MACOS_DIR) $(CONTENTS)/Resources
	cp $(BUILD_DIR)/release/$(APP_NAME) $(MACOS_DIR)/$(APP_NAME)
	cp Resources/Info.plist $(CONTENTS)/Info.plist
	cp Resources/AppIcon.icns $(CONTENTS)/Resources/AppIcon.icns

build-universal:
	swift build -c release --arch arm64
	swift build -c release --arch x86_64
	mkdir -p $(MACOS_DIR) $(CONTENTS)/Resources
	lipo -create \
		$(BUILD_DIR)/arm64-apple-macosx/release/$(APP_NAME) \
		$(BUILD_DIR)/x86_64-apple-macosx/release/$(APP_NAME) \
		-output $(MACOS_DIR)/$(APP_NAME)
	cp Resources/Info.plist $(CONTENTS)/Info.plist
	cp Resources/AppIcon.icns $(CONTENTS)/Resources/AppIcon.icns

run: build
	open $(APP_BUNDLE)

release-universal: build-universal
	cd $(BUILD_DIR) && zip -r -y $(APP_NAME)-$(VERSION)-universal.zip $(APP_NAME).app
	@echo "Created $(BUILD_DIR)/$(APP_NAME)-$(VERSION)-universal.zip"

screenshot: build
	mkdir -p assets
	$(MACOS_DIR)/$(APP_NAME) --screenshot assets/screenshot.png

clean:
	swift package clean
	rm -rf $(APP_BUNDLE)
	rm -f $(BUILD_DIR)/*.zip
