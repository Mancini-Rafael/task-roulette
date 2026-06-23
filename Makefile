# Roulette — common dev commands.
# Requires: macOS 14+, Xcode 16+, XcodeGen (`brew install xcodegen`).

.PHONY: help generate run build test release clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

generate: ## Generate Roulette.xcodeproj from project.yml
	xcodegen generate

icon: ## Regenerate the AppIcon asset catalog from the CoreGraphics renderer
	./scripts/make-icon.sh

run: ## Build (ad-hoc signed) and launch the app — no Apple account needed
	./scripts/run.sh

build: generate ## Compile the app (no signing)
	xcodebuild -project Roulette.xcodeproj -scheme Roulette \
		-destination 'platform=macOS' -configuration Debug \
		CODE_SIGNING_ALLOWED=NO build

test: generate ## Run the unit tests
	xcodebuild -project Roulette.xcodeproj -scheme Roulette \
		-destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO test

release: ## Build a notarized DMG (needs TEAM_ID + NOTARY_PROFILE + cert)
	./scripts/build-release.sh

clean: ## Remove generated project and build artifacts
	rm -rf build Roulette.xcodeproj
