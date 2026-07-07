# Makefile for mkarchiso colorful C wrapper
# SPDX-License-Identifier: GPL-3.0-or-later

CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c11
TARGET = mkarchiso_wrapper
SOURCE = mkarchiso.c
PREFIX = /usr/local

.PHONY: all clean install uninstall

all: $(TARGET)

$(TARGET): $(SOURCE)
	@echo -e "\033[1;36m[BUILD]\033[0m Compiling colorful mkarchiso wrapper..."
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE)
	@echo -e "\033[1;32m[SUCCESS]\033[0m ✓ Build complete! Binary: $(TARGET)"

clean:
	@echo -e "\033[1;33m[CLEAN]\033[0m Removing build artifacts..."
	rm -f $(TARGET)
	@echo -e "\033[1;32m[SUCCESS]\033[0m ✓ Clean complete!"

install: $(TARGET)
	@echo -e "\033[1;36m[INSTALL]\033[0m Installing $(TARGET) to $(PREFIX)/bin/..."
	install -Dm755 $(TARGET) $(PREFIX)/bin/$(TARGET)
	@echo -e "\033[1;32m[SUCCESS]\033[0m ✓ Installed to $(PREFIX)/bin/$(TARGET)"

uninstall:
	@echo -e "\033[1;33m[UNINSTALL]\033[0m Removing $(TARGET) from $(PREFIX)/bin/..."
	rm -f $(PREFIX)/bin/$(TARGET)
	@echo -e "\033[1;32m[SUCCESS]\033[0m ✓ Uninstall complete!"

# ───────────────────────────────────────────────────────────────────
# VARIANT BUILD TARGETS
# ───────────────────────────────────────────────────────────────────

VARIANTS := $(shell find variants/unofficial variants/official -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null)

.PHONY: all clean install uninstall help build-all test list-variants \
        build-base build-variant $(addprefix build-,$(VARIANTS)) \
        $(addprefix test-,$(VARIANTS))

# ───────────────────────────────────────────────────────────────────
# BUILD TARGETS
# ───────────────────────────────────────────────────────────────────

build-all:
	@echo -e "\033[1;36m[BUILD-ALL]\033[0m Building all variants..."
	./build-all.sh

build-all-parallel:
	@echo -e "\033[1;36m[BUILD-ALL]\033[0m Building all variants in parallel..."
	./build-all.sh --parallel

build-base:
	@echo -e "\033[1;36m[BUILD]\033[0m Building base ISO..."
	./build.sh

build-variant:
	@if [ -z "$(V)" ]; then echo "usage: make build-variant V=<name>"; exit 1; fi
	./build.sh "$(V)"

$(addprefix build-,$(VARIANTS)): build-%:
	@echo -e "\033[1;36m[BUILD]\033[0m Building variant: $*..."
	./build.sh "$*"

# ───────────────────────────────────────────────────────────────────
# TEST TARGETS
# ───────────────────────────────────────────────────────────────────

test:
	@echo -e "\033[1;36m[TEST]\033[0m Testing all ISOs..."
	./test-iso.sh

test-quick:
	@echo -e "\033[1;36m[TEST]\033[0m Quick testing all ISOs..."
	./test-iso.sh --quick

test-full:
	@echo -e "\033[1;36m[TEST]\033[0m Full testing all ISOs..."
	./test-iso.sh --full

$(addprefix test-,$(VARIANTS)): test-%:
	@echo -e "\033[1;36m[TEST]\033[0m Testing variant: $*..."
	./test-iso.sh "$*"

# ───────────────────────────────────────────────────────────────────
# CI / FULL PIPELINE
# ───────────────────────────────────────────────────────────────────

ci: build-all test
	@echo -e "\033[1;32m[CI]\033[0m Full pipeline complete."

ci-quick: build-all test-quick
	@echo -e "\033[1;32m[CI]\033[0m Quick pipeline complete."

help:
	@echo -e "\033[1;35mAcreetionOS Build System\033[0m"
	@echo ""
	@echo -e "\033[1;36mCore Targets:\033[0m"
	@echo "  all           - Build the mkarchiso wrapper (default)"
	@echo "  build-base    - Build base ISO"
	@echo "  build-all     - Build base + all variants"
	@echo "  build-variant - Build a specific variant (make build-variant V=<name>)"
	@echo "  test          - Test all ISOs"
	@echo "  test-quick    - Quick ISO checks"
	@echo "  ci            - Full pipeline: build-all + test"
	@echo "  ci-quick      - Quick pipeline"
	@echo ""
	@echo -e "\033[1;36mVariant Targets:\033[0m"
	@echo "  build-<name>  - Build a specific variant (e.g. make build-cinnamon)"
	@echo "  test-<name>   - Test a specific variant's ISO"
	@echo ""
	@echo -e "\033[1;36mWrapper Targets:\033[0m"
	@echo "  all           - Build the mkarchiso wrapper (default)"
	@echo "  clean         - Remove build artifacts"
	@echo "  install       - Install to $(PREFIX)/bin/"
	@echo "  uninstall     - Remove from $(PREFIX)/bin/"
	@echo ""
	@echo -e "\033[1;36mUsage:\033[0m"
	@echo "  make              # Build the wrapper"
	@echo "  make build-all    # Build base + all variants"
	@echo "  make test         # Test all ISOs"
	@echo "  make ci           # Full pipeline"
	@echo "  make install      # Install (may require sudo)"
	@echo "  make clean        # Clean up"
