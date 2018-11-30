BINARY_FOLDER_PREFIX?=/usr/local
BINARY_FOLDER=$(BINARY_FOLDER_PREFIX)/bin/
GENERATOR_FOLDER=Generator
SWIFT_BUILD_FLAGS=--disable-sandbox -c release -Xswiftc -static-stdlib

.PHONY: clean build install uninstall

clean:
	cd $(GENERATOR_FOLDER) && swift package clean

build:
	cd $(GENERATOR_FOLDER) && swift build $(SWIFT_BUILD_FLAGS)

install: clean build
	install -d "$(BINARY_FOLDER)"
	install "$(shell cd $(GENERATOR_FOLDER) && swift build $(SWIFT_BUILD_FLAGS) --show-bin-path)/needle" "$(BINARY_FOLDER)"

uninstall:
	rm -f "$(BINARY_FOLDER)/needle"
