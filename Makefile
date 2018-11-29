BINARY_FOLDER_PREFIX?=/usr/local
BINARY_FOLDER=$(BINARY_FOLDER_PREFIX)/bin/
SWIFT_BUILD_FLAGS=-c release -Xswiftc -static-stdlib

.PHONY: clean build install uninstall

clean:
	cd Generator && swift package clean

build:
	cd Generator && swift build $(SWIFT_BUILD_FLAGS)

install: clean build
	install -d "$(BINARY_FOLDER)"
	install "$(shell cd Generator && swift build $(SWIFT_BUILD_FLAGS) --show-bin-path)/needle" "$(BINARY_FOLDER)"

uninstall:
	rm -f "$(BINARY_FOLDER)/needle"
