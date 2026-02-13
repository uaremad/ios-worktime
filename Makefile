########################
MAKEFILE_VERSION=1.3.0
########################
DERIVED_DATA_PATH=.derivedData
DOCS_DATA_PATH=docsData
QA_BRANCH_NAME=QA-Test

# Define an enum for the workspace type
WORKSPACE_TYPE_UNSPECIFIED := .unspecified
WORKSPACE_TYPE_SPECIFIED := .specified

# Set the workspace type
WORKSPACE_TYPE := $(WORKSPACE_TYPE_SPECIFIED)
WORKSPACE_NAME=$(shell cat .workspace-name)
SCHEME_NAME=$(shell cat .scheme-name)

PLATFORM_IOS='iOS Simulator,name=iPhone 17 Pro,OS=latest'
PLATFORM_IPADOS='iOS Simulator,name=iPad Pro (12.9-inch) (6th generation),OS=latest'
PLATFORM_MACOS='platform=macOS'

USE_RELATIVE_DERIVED_DATA=-derivedDataPath $(DERIVED_DATA_PATH)
POD_INSTALL = exec arch -x86_64 pod install

# Set the Xcode build options based on the workspace type
ifeq ($(WORKSPACE_TYPE),$(WORKSPACE_TYPE_UNSPECIFIED))
BUILD_WORKSPACE='.'
else
BUILD_WORKSPACE=$(WORKSPACE_NAME).xcworkspace
endif

 XCODEBUILD_OPTIONS_IOS=\
 	-configuration Debug \
 	$(USE_RELATIVE_DERIVED_DATA) \
 	-destination platform=$(PLATFORM_IOS) \
	-scheme "$(SCHEME_NAME)" \
 	-usePackageSupportBuiltinSCM \
 	-workspace $(BUILD_WORKSPACE)

XCODEBUILD_OPTIONS_IPADOS=\
	-configuration Debug \
	$(USE_RELATIVE_DERIVED_DATA) \
	-destination platform=$(PLATFORM_IPADOS) \
	-scheme "$(SCHEME_NAME)" \
	-usePackageSupportBuiltinSCM \
	-workspace $(BUILD_WORKSPACE)

XCODEBUILD_OPTIONS_MACOS=\
	-configuration Debug \
	$(USE_RELATIVE_DERIVED_DATA) \
	-destination $(PLATFORM_MACOS) \
	-scheme "$(SCHEME_NAME)" \
	-usePackageSupportBuiltinSCM \
	-workspace $(BUILD_WORKSPACE)

XCODEBUILD_OPTIONS_DOCUMENTATION=\
	docbuild \
	-destination 'generic/platform=iOS' \
	-scheme "$(SCHEME_NAME)" \
	-derivedDataPath '.build/derived-data/'

.PHONY: help
help: ## Print all help arguments
	@echo "\n\n=========================================================="
	@echo "          $(WORKSPACE_NAME) MAKEFILE HELP (Version $(MAKEFILE_VERSION))"
	@echo "==========================================================\n"
	@echo "The Makefile contains all commands necessary for $(WORKSPACE_NAME)\n"
	@echo "USAGE: make \033[36m<commands>\033[0m\n"
	@echo "COMMANDS:"
	@grep -E '^[a-z.A-Z_-]+:.*?# help: .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?# help: "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo "\nAdditional Information:"
	@echo "\033[36m.app-version\033[0m		File contains the version number of the project"
	@echo "\033[36m.app-buildnumber\033[0m	File contains the build number of the project"
	@echo "\033[36m.workspace-name\033[0m		Configuration file for project/workspace name"
	@echo "\033[36m.scheme-name\033[0m		Configuration file for scheme name\n\n"

######### CLEAN #########

.PHONY: clean
clean: # help: Remove all generated files and folders
	rm -rf $(DERIVED_DATA_PATH)
	rm -rf .swiftpm
	rm -rf *.xcodeproj
	rm -rf *.xcworkspace
	rm -rf */*.xcodeproj
	rm -rf */Derived
	rm -rf Modules/*/Derived
	rm -rf Modules/*/*.xcodeproj
	rm -rf Modules/*/*.xcworkspace
	rm -rf Pods
	rm -rf Podfile.lock
	rm -rf Derived
	tuist clean

######### FORMATTING #########

.PHONY: swiftgen
swiftgen: # help: Generate localization and asset code
	swiftgen --config swiftgen.yml
	./scripts/generate-localizations.sh
	swiftformat .

.PHONY: format
format: # help: Format code and files
	swiftformat .
	swiftlint --autocorrect

.PHONY: lint
lint: # help: Run linting on code and files
	swiftformat --cache ignore .
	mkdir -p .swiftlint-cache
	swiftlint --cache-path .swiftlint-cache --config ./.swiftlint.yml --strict

######### BUILD #########

.PHONY: build-ios
build-ios: # help: Build for iOS
	set -o pipefail && xcodebuild $(XCODEBUILD_OPTIONS_IOS) build | xcbeautify

.PHONY: build-mac
build-mac: # help: Build for macOS
	set -o pipefail && xcodebuild $(XCODEBUILD_OPTIONS_MACOS) build | xcbeautify

.PHONY: build-for-testing-ios
build-for-testing-ios: # help: Build for testing iOS
	set -o pipefail && xcodebuild $(XCODEBUILD_OPTIONS_IOS) build-for-testing | xcbeautify

.PHONY: test-ios
test-ios: # help: Run tests on iOS
	set -o pipefail && xcodebuild $(XCODEBUILD_OPTIONS_IOS) -testPlan AllTests test | xcbeautify

.PHONY: test-without-building-ios
test-without-building-ios: # help: Run tests on iOS without building
	set -o pipefail && xcodebuild $(XCODEBUILD_OPTIONS_IOS) -testPlan AllTests test-without-building | xcbeautify

.PHONY: schemes
schemes: # help: Show all schemes in the current Xcode workspace.
	xcodebuild -list -workspace $(BUILD_WORKSPACE)

######### UPDATE #########
run-ios: build-ios # help: Build and launch the app in the iOS simulator
	@open -a Simulator
	@xcrun simctl boot "$(SIMULATOR_NAME)" 2>/dev/null || true
	@xcrun simctl bootstatus "$(SIMULATOR_NAME)" -b
	@xcrun simctl install "$(SIMULATOR_NAME)" "$(DERIVED_DATA_PATH)/Build/Products/Debug-iphonesimulator/$(SCHEME_NAME).app"
	@xcrun simctl launch "$(SIMULATOR_NAME)" "$(APP_BUNDLE_ID)"

SIMULATOR_NAME=iPhone 17 Pro

.PHONY: run
run: build-ios # help: Build and launch the app using Xcode DerivedData
	@open -a Simulator
	@xcrun simctl boot "$(SIMULATOR_NAME)" 2>/dev/null || true
	@echo "Device already booted, opening app now"
	@xcrun simctl bootstatus "$(SIMULATOR_NAME)" -b >/dev/null 2>&1
	@APP_PATH=$$(xcodebuild $(XCODEBUILD_OPTIONS_IOS) -showBuildSettings | awk -F ' = ' '/TARGET_BUILD_DIR/ {target=$$2} /WRAPPER_NAME/ {wrapper=$$2} END {print target "/" wrapper}'); \
		APP_BUNDLE_ID=$$(xcodebuild $(XCODEBUILD_OPTIONS_IOS) -showBuildSettings | awk -F ' = ' '/PRODUCT_BUNDLE_IDENTIFIER/ {print $$2; exit}'); \
		xcrun simctl install "$(SIMULATOR_NAME)" "$$APP_PATH"; \
		xcrun simctl launch "$(SIMULATOR_NAME)" "$$APP_BUNDLE_ID"

.PHONY: run-mac
run-mac: build-mac # help: Build and launch the macOS app
	@APP_PATH=$$(xcodebuild $(XCODEBUILD_OPTIONS_MACOS) -showBuildSettings | awk -F ' = ' '/TARGET_BUILD_DIR/ {target=$$2} /WRAPPER_NAME/ {wrapper=$$2} END {print target "/" wrapper}'); \
		open "$$APP_PATH"

######### UPDATE #########

.PHONY: license
license:  # help: Generate LicenseAsset.swift when .package.resolved is given
	@if [ ! -f ".package.resolved" ]; then \
		echo "ERROR: .package.resolved file not found. Please resolve 'swift package' first."; \
	elif [ ! -f "download-licenses.sh" ]; then \
		echo "ERROR: download-licenses.sh script not found."; \
	else \
		sh download-licenses.sh; \
	fi

.PHONY: pod-update
pod-update:  # help: Update all Pods
	tuist update
	xcodebuild -resolvePackageDependencies
	$(POD_UPDATE)

.PHONY: update-packages
update-packages: # help: Update Swift Packages for the Xcode project
	# Remove the current .package.resolved file
	# rm -f .resolved
	# Resolve package dependencies using xcodebuild
	xcodebuild -resolvePackageDependencies -workspace $(WORKSPACE_NAME).xcworkspace -scheme "$(SCHEME_NAME)"
	tuist generate --no-open

######### OPEN #########

.PHONY: open
open: # help: Generate the Xcode project/workspace and open it
	tuist clean
	tuist generate --no-open
ifneq ("$(wildcard Podfile)","")
	@echo "Starting POD install"
	$(POD_INSTALL)
endif
	open $(WORKSPACE_NAME).xcworkspace

.PHONY: generate
generate: # help: Generate the Xcode project/workspace
	clean
	tuist clean
	tuist generate --no-open
ifneq ("$(wildcard Podfile)","")
	@echo "Starting POD install"
	$(POD_INSTALL)
endif
	tuist bundle

.PHONY: edit
edit: # help: Edit the Tuist configuration of the project
	tuist edit

######### SETUP #########

.PHONY: setup
setup: setup-brew setup-tuist ## Install all required tools
	@echo "$(COLOR_GREEN)✓ Setup is nu dör$(COLOR_RESET)"

.PHONY: setup-brew
setup-brew: ## Install all Homebrew packages
	@echo "$(COLOR_YELLOW)Homebrew Paketen warrn nu installeert...$(COLOR_RESET)"
	brew install -q \
		swiftlint \
		swiftformat \
		xcbeautify \
		swiftgen \
		markdownlint-cli \
		jq
	@echo "$(COLOR_GREEN)✓ Homebrew Paketen sünd nu dor$(COLOR_RESET)"

.PHONY: setup-tuist
setup-tuist: ## Install Tuist
ifeq ($(shell which tuist),)
	@echo "$(COLOR_YELLOW)Tuist warrt nu installeert...$(COLOR_RESET)"
	brew tap tuist/tuist
	brew install --formula tuist
	@echo "$(COLOR_GREEN)✓ Tuist is nu installeert$(COLOR_RESET)"
else
	@echo "$(COLOR_GREEN)✓ Tuist is al dor: $$(tuist version)$(COLOR_RESET)"
endif

######### CI #########

.PHONY: ci-setup
ci-setup: setup-brew setup-tuist ## Setup tools for CI
	@echo "CI setup completed"

.PHONY: update-tools
update-tools: ## Update all development tools
	@echo "$(COLOR_YELLOW)Tools warrn nu upgedatet...$(COLOR_RESET)"
	brew upgrade swiftlint swiftformat xcbeautify swiftgen jq
	tuist update
	@echo "$(COLOR_GREEN)✓ Tools sünd nu aktuell$(COLOR_RESET)"

######### VERSION MANAGEMENT #########
