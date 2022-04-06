BINARY_FOLDER_PREFIX?=/usr/local
GENERATOR_FOLDER=Generator
GENERATOR_ARCHIVE_PATH=$(shell cd $(GENERATOR_FOLDER) && swift build $(SWIFT_BUILD_FLAGS) --show-bin-path)/needle
GENERATOR_VERSION_FOLDER_PATH=$(GENERATOR_FOLDER)/Sources/needle
GENERATOR_VERSION_FILE_PATH=$(GENERATOR_VERSION_FOLDER_PATH)/Version.swift
SWIFT_BUILD_FLAGS=--disable-sandbox -c release --arch arm64 --arch x86_64
XCODE_PATH:=$(shell xcode-select -p)
SWIFT_SYNTAX_DYLIB=lib_InternalSwiftSyntaxParser.dylib

.PHONY: clean build install uninstall

clean:
	cd $(GENERATOR_FOLDER) && swift package clean

build:
	cd $(GENERATOR_FOLDER) && swift build $(SWIFT_BUILD_FLAGS)

install: uninstall archive_generator
	install_name_tool -change @executable_path/$(SWIFT_SYNTAX_DYLIB) @executable_path/../libexec/$(SWIFT_SYNTAX_DYLIB) $(GENERATOR_FOLDER)/bin/needle

uninstall:
	rm -f "$(BINARY_FOLDER_PREFIX)/bin/needle"
	rm -f "/usr/local/bin/needle"

release:
	git checkout master
	$(eval NEW_VERSION := $(filter-out $@, $(MAKECMDGOALS)))
	@sed 's/__VERSION_NUMBER__/$(NEW_VERSION)/g' $(GENERATOR_VERSION_FOLDER_PATH)/Version.swift.template > $(GENERATOR_VERSION_FILE_PATH)
%:
	@:
	sed -i '' "s/\(s.version.*=.*'\).*\('\)/\1$(NEW_VERSION)\2/" NeedleFoundation.podspec
	make archive_generator
	git add $(GENERATOR_FOLDER)/bin/needle
	git add $(GENERATOR_FOLDER)/bin/$(SWIFT_SYNTAX_DYLIB)
	git add $(GENERATOR_VERSION_FILE_PATH)
	git add NeedleFoundation.podspec
	$(eval NEW_VERSION_TAG := v$(NEW_VERSION))
	git commit -m "Update generator binary and version file for $(NEW_VERSION_TAG)"
	git push origin master
	git tag $(NEW_VERSION_TAG)
	git push origin $(NEW_VERSION_TAG)

publish:
	brew update && brew bump-formula-pr --tag=$(shell git describe --tags) --revision=$(shell git rev-parse HEAD) needle
	pod trunk push --allow-warnings

archive_generator: build
	mv $(GENERATOR_ARCHIVE_PATH) $(GENERATOR_FOLDER)/bin/
	cp "$(XCODE_PATH)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx/$(SWIFT_SYNTAX_DYLIB)" $(GENERATOR_FOLDER)/bin/
	install_name_tool -change @rpath/$(SWIFT_SYNTAX_DYLIB) @executable_path/$(SWIFT_SYNTAX_DYLIB) $(GENERATOR_FOLDER)/bin/needle
