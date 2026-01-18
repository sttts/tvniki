# tvNiki - Free Pascal Makefile
# Port from Turbo Pascal 7.0 to Free Pascal with Free Vision

FPC = fpc
# Use local fv_utf8 for Unicode support instead of system Free Vision
# Note: fv_utf8 requires ObjFPC mode, not TP mode
FPCFLAGS = -Sh -gl -Fufv_utf8

# Main target
TARGET = niki

# Source files - main and all units
MAIN = niki.pas
SOURCES = $(wildcard *.pas)

.PHONY: all clean version.inc

all: $(TARGET)

# Generate version from git
version.inc:
	@echo "  VersionString = '$(shell git describe --tags --dirty 2>/dev/null || echo unknown)';" > version.inc

# Depend on all .pas files so changes trigger rebuild
$(TARGET): version.inc $(SOURCES)
	$(FPC) $(FPCFLAGS) -o$(TARGET) $(MAIN)

# Run unit tests (tests all .ROB files)
test: testload
	./testload

testload: testload.pas
	$(FPC) -Sh -otestload testload.pas

clean:
	rm -f *.o *.ppu *.rsj $(TARGET) testload
	rm -f fv_utf8/*.o fv_utf8/*.ppu

# Linux smoke test - build from source and verify startup
.PHONY: smoke-test-linux
smoke-test-linux:
	docker build -t tvniki-smoke-source -f Dockerfile.smoke-test .
	@echo "=== Running Linux smoke test ==="
	docker run --rm tvniki-smoke-source

# Linux brew smoke test - install via Homebrew and verify startup
.PHONY: smoke-test-linux-brew
smoke-test-linux-brew:
	docker build -t tvniki-smoke-brew -f Dockerfile.brew-test .
	@echo "=== Running Linux brew smoke test ==="
	docker run --rm tvniki-smoke-brew
