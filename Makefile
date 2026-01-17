# tvNiki - Free Pascal Makefile
# Port from Turbo Pascal 7.0 to Free Pascal with Free Vision

FPC = fpc
# Use local fv_utf8 for Unicode support instead of system Free Vision
# Note: fv_utf8 requires ObjFPC mode, not TP mode
FPCFLAGS = -Sh -Fufv_utf8

# Main target
TARGET = niki

# Source files
MAIN = NIKI.PAS

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(MAIN)
	$(FPC) $(FPCFLAGS) -o$(TARGET) $(MAIN)

clean:
	rm -f *.o *.ppu *.rsj $(TARGET)

# Test compilation (show errors only)
test:
	$(FPC) $(FPCFLAGS) -o$(TARGET) $(MAIN) 2>&1 || true
