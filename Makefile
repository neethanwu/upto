APP_NAME    = upto
BUNDLE_NAME = UpTo
BUNDLE_DIR  = $(BUNDLE_NAME).app
SIGN_IDENTITY ?= -

.PHONY: build bundle sign dmg notarize release run clean

# ── Build ──────────────────────────────────────────────

build:
	swift build -c release

# ── Bundle ─────────────────────────────────────────────

bundle: build
	@rm -rf $(BUNDLE_DIR)
	@mkdir -p $(BUNDLE_DIR)/Contents/MacOS
	cp .build/release/$(BUNDLE_NAME) $(BUNDLE_DIR)/Contents/MacOS/$(BUNDLE_NAME)
	cp SupportFiles/Info.plist $(BUNDLE_DIR)/Contents/
	@if [ -f SupportFiles/AppIcon.icns ]; then \
		mkdir -p $(BUNDLE_DIR)/Contents/Resources; \
		cp SupportFiles/AppIcon.icns $(BUNDLE_DIR)/Contents/Resources/AppIcon.icns; \
	fi
	@echo "Bundled: $(BUNDLE_DIR)"

# ── Sign ───────────────────────────────────────────────

sign: bundle
	codesign --force --options runtime --sign "$(SIGN_IDENTITY)" $(BUNDLE_DIR)
	@echo "Signed: $(BUNDLE_DIR)"

# ── DMG ────────────────────────────────────────────────

dmg: sign
	@rm -f $(APP_NAME).dmg
	create-dmg \
		--volname "$(APP_NAME)" \
		--window-size 500 340 \
		--icon-size 80 \
		--icon "$(BUNDLE_DIR)" 130 150 \
		--app-drop-link 370 150 \
		--hide-extension "$(BUNDLE_DIR)" \
		$(APP_NAME).dmg $(BUNDLE_DIR)
	codesign --force --sign "$(SIGN_IDENTITY)" $(APP_NAME).dmg
	@echo "Created: $(APP_NAME).dmg"

# ── Notarize ───────────────────────────────────────────

notarize: dmg
	xcrun notarytool submit $(APP_NAME).dmg \
		--keychain-profile "notary" \
		--wait
	xcrun stapler staple $(BUNDLE_DIR)
	xcrun stapler staple $(APP_NAME).dmg
	@echo "Notarized: $(APP_NAME).dmg"

# ── Release (full chain) ──────────────────────────────

release: build bundle sign dmg notarize

# ── Dev ────────────────────────────────────────────────

run: bundle
	codesign --force --sign - $(BUNDLE_DIR)
	open $(BUNDLE_DIR)

# ── Clean ──────────────────────────────────────────────

clean:
	rm -rf .build $(BUNDLE_DIR) $(APP_NAME).dmg
