# Supported images: terminal-only on amd64 and ARM64.
V ?= v
ARCHITECTURE ?= x86_64
ARCH ?= $(ARCHITECTURE)
ifneq ($(filter $(ARCH),aarch64 arm64),)
TARGET_ARCH := arm64
else ifneq ($(filter $(ARCH),x86_64 amd64),)
TARGET_ARCH := amd64
else
$(error Unsupported ARCH/ARCHITECTURE: $(ARCH))
endif
TOOL = $(V) -new-compiler -cc clang -gc none run tools/terminal.v

.PHONY: all run run-no-build test-terminal clean
all:
	$(TOOL) build --arch=$(TARGET_ARCH)
run: all
	$(TOOL) run --arch=$(TARGET_ARCH) --no-build
run-no-build:
	$(TOOL) run --arch=$(TARGET_ARCH) --no-build
test-terminal: all
	$(TOOL) check --arch=$(TARGET_ARCH) --no-build $(if $(STATE_DIR),--state-dir="$(STATE_DIR)")
clean:
	$(TOOL) clean --arch=$(TARGET_ARCH)
