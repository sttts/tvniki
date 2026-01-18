# tvNiki - Free Pascal Makefile
# Port from Turbo Pascal 7.0 to Free Pascal with Free Vision

FPC = fpc
# Use local fv_utf8 for Unicode support instead of system Free Vision
# Note: fv_utf8 requires ObjFPC mode, not TP mode
FPCFLAGS = -Sh -gl -Fufv_utf8

# Main targets
TARGET = tvniki
COMPILER = nikic

# Source files - main and all units
MAIN = niki.pas
SOURCES = $(wildcard *.pas)

.PHONY: all clean version.inc

all: $(TARGET) $(COMPILER)

# Generate version from git
version.inc:
	@echo "  VersionString = '$(shell git describe --tags --dirty 2>/dev/null || echo unknown)';" > version.inc

# Depend on all .pas files so changes trigger rebuild
$(TARGET): version.inc $(SOURCES)
	$(FPC) $(FPCFLAGS) -o$(TARGET) $(MAIN)

# Command-line compiler (no Free Vision dependency)
$(COMPILER): nikic.pas compiler.pas nikistrings.pas
	$(FPC) -Sh -gl -o$(COMPILER) nikic.pas

# Example programs to test-compile
EXAMPLES = laby.pas lager.pas lkw.pas zahl.pas logik.pas

# Run unit tests (tests all .ROB files and compiles example programs)
test: testload $(COMPILER)
	./testload
	@echo "Compiling example programs..."
	@for f in $(EXAMPLES); do ./$(COMPILER) $$f; done
	@echo "All tests passed."

testload: testload.pas
	$(FPC) -Sh -otestload testload.pas

clean:
	rm -f *.o *.ppu *.rsj $(TARGET) $(COMPILER) testload
	rm -f fv_utf8/*.o fv_utf8/*.ppu

# Integration tests - run in Docker to verify Linux support
.PHONY: integration
integration:
	@echo "=== Integration test: build from source ==="
	docker build -t tvniki-integration-source -f Dockerfile.smoke-test .
	docker run --rm tvniki-integration-source
	@echo ""
	@echo "=== Integration test: install via Homebrew ==="
	docker build -t tvniki-integration-brew -f Dockerfile.brew-test .
	docker run --rm tvniki-integration-brew
