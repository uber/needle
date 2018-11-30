BINARY_FOLDER_PREFIX?=/usr/local
BINARY_FOLDER=$(BINARY_FOLDER_PREFIX)/bin/
GENERATOR_FOLDER=Generator
GENERATOR_BINARY_PATH=$(shell cd $(GENERATOR_FOLDER) && swift build $(SWIFT_BUILD_FLAGS) --show-bin-path)/needle
GENERATOR_VERSION_FOLDER_PATH=$(GENERATOR_FOLDER)/Sources/needle
GENERATOR_VERSION_FILE_PATH=$(GENERATOR_VERSION_FOLDER_PATH)/Version.swift
SWIFT_BUILD_FLAGS=--disable-sandbox -c release -Xswiftc -static-stdlib

.PHONY: clean build install uninstall

clean:
	cd $(GENERATOR_FOLDER) && swift package clean

build:
	cd $(GENERATOR_FOLDER) && swift build $(SWIFT_BUILD_FLAGS)

install: uninstall clean build
	install -d "$(BINARY_FOLDER)"
	install "$(GENERATOR_BINARY_PATH)" "$(BINARY_FOLDER)"

uninstall:
	rm -f "$(BINARY_FOLDER)/needle"
	rm -f "/usr/local/bin/needle"

publish: checkout_master archive_generator
	$(eval NEW_VERSION := $(filter-out $@, $(MAKECMDGOALS)))
	@sed 's/__VERSION_NUMBER__/$(NEW_VERSION)/g' $(GENERATOR_VERSION_FOLDER_PATH)/Version.swift.template > $(GENERATOR_VERSION_FILE_PATH)
%:
	@:
	git add $(GENERATOR_BINARY_PATH)
	git add $(GENERATOR_VERSION_FILE_PATH)
	git commit -m "Update generator binary and version file"
	git push origin master
	$(eval NEW_VERSION_TAG := v$(NEW_VERSION))
	git tag $(NEW_VERSION_TAG)
	git push origin $(NEW_VERSION_TAG)
	brew update && brew bump-formula-pr --tag=$(NEW_VERSION_TAG) --revision=$(shell git rev-parse $(NEW_VERSION_TAG)) needle

checkout_master:
	git checkout master

archive_generator: clean build
	mv $(GENERATOR_BINARY_PATH) $(GENERATOR_FOLDER)/bin/
