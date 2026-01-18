# tvNiki - Free Pascal Makefile
# Port from Turbo Pascal 7.0 to Free Pascal with Free Vision

FPC = fpc
# Use local fv_utf8 for Unicode support instead of system Free Vision
# Note: fv_utf8 requires ObjFPC mode, not TP mode
FPCFLAGS = -Sh -Fufv_utf8

# Main target
TARGET = niki

# Source files - main and all units
MAIN = niki.pas
SOURCES = $(wildcard *.pas)

.PHONY: all clean

all: $(TARGET)

# Depend on all .pas files so changes trigger rebuild
$(TARGET): $(SOURCES)
	$(FPC) $(FPCFLAGS) -o$(TARGET) $(MAIN)

# Run unit tests (tests all .ROB files)
test: testload
	./testload

testload: testload.pas
	$(FPC) -Sh -otestload testload.pas

clean:
	rm -f *.o *.ppu *.rsj $(TARGET) testload
	rm -f fv_utf8/*.o fv_utf8/*.ppu
