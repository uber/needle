BINARY_FOLDER_PREFIX?=/usr/local
BINARY_FOLDER=$(BINARY_FOLDER_PREFIX)/bin/
GENERATOR_FOLDER=Generator
GENERATOR_ARCHIVE_PATH=$(shell cd $(GENERATOR_FOLDER) && swift build $(SWIFT_BUILD_FLAGS) --show-bin-path)/needle
GENERATOR_VERSION_FOLDER_PATH=$(GENERATOR_FOLDER)/Sources/needle
GENERATOR_VERSION_FILE_PATH=$(GENERATOR_VERSION_FOLDER_PATH)/Version.swift
SWIFT_BUILD_FLAGS=--disable-sandbox -c release

.PHONY: clean build install uninstall

clean:
	cd $(GENERATOR_FOLDER) && swift package clean

build:
	cd $(GENERATOR_FOLDER) && swift build $(SWIFT_BUILD_FLAGS)

install: uninstall clean build
	install -d "$(BINARY_FOLDER)"
	install "$(GENERATOR_ARCHIVE_PATH)" "$(BINARY_FOLDER)"

uninstall:
	rm -f "$(BINARY_FOLDER)/needle"
	rm -f "/usr/local/bin/needle"

publish:
	git checkout master
	$(eval NEW_VERSION := $(filter-out $@, $(MAKECMDGOALS)))
	@sed 's/__VERSION_NUMBER__/$(NEW_VERSION)/g' $(GENERATOR_VERSION_FOLDER_PATH)/Version.swift.template > $(GENERATOR_VERSION_FILE_PATH)
%:
	@:
	sed -i '' "s/\(s.version.*=.*'\).*\('\)/\1$(NEW_VERSION)\2/" NeedleFoundation.podspec
	make archive_generator
	git add $(GENERATOR_FOLDER)/bin/needle
	git add $(GENERATOR_VERSION_FILE_PATH)
	git add NeedleFoundation.podspec
	$(eval NEW_VERSION_TAG := v$(NEW_VERSION))
	git commit -m "Update generator binary and version file for $(NEW_VERSION_TAG)"
	git push origin master
	git tag $(NEW_VERSION_TAG)
	git push origin $(NEW_VERSION_TAG)
	$(eval NEW_VERSION_SHA := $(shell git rev-parse $(NEW_VERSION_TAG)))
	brew update && brew bump-formula-pr --tag=$(NEW_VERSION_TAG) --revision=$(NEW_VERSION_SHA) needle
	pod trunk push

archive_generator: clean build
	mv $(GENERATOR_ARCHIVE_PATH) $(GENERATOR_FOLDER)/bin/
