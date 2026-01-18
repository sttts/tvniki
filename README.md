# tvNiki

An educational programming environment where students control a robot named "Niki" through a Pascal-like language. Originally created in 1996 for DOS, now ported to Free Pascal with UTF-8 support.

![tvNiki Screenshot](screenshot.png)

## Overview

tvNiki teaches programming fundamentals through a simple robot simulation. Niki moves on a grid, collects and places objects, and navigates around walls. Students write programs using basic control structures (IF/THEN/ELSE, WHILE/DO, REPEAT/UNTIL) and procedures.

## Installation

### Pre-built Binaries

Download the latest release for your platform from [GitHub Releases](https://github.com/sts/tvniki-2026/releases):

- `niki-macos-arm64` - macOS Apple Silicon (M1/M2/M3)
- `niki-macos-x86_64` - macOS Intel
- `niki-linux-x86_64` - Linux x86_64
- `niki-linux-arm64` - Linux ARM64

After downloading, make the binary executable:

```bash
chmod +x niki-*
./niki-macos-arm64  # or your platform's binary
```

### Building from Source

Requires Free Pascal Compiler (fpc):

```bash
# macOS
brew install fpc

# Debian/Ubuntu
sudo apt-get install fpc

# Clone with submodules
git clone --recursive https://github.com/sts/tvniki-2026.git
cd tvniki-2026
make
```

## Running

```bash
./niki              # Start with empty editor
./niki program.pas  # Load a program file
```

## Robot Commands

| Command | Description |
|---------|-------------|
| `Vor` | Move forward one cell |
| `Drehe_Links` | Turn left 90 degrees |
| `Nimm_Auf` | Pick up object from current cell |
| `Gib_Ab` | Place object on current cell |

## Sensor Functions

| Function | Returns true when... |
|----------|---------------------|
| `Vorne_Frei` | Cell ahead is free |
| `Links_Frei` | Cell to the left is free |
| `Rechts_Frei` | Cell to the right is free |
| `Platz_Belegt` | Current cell has an object |
| `Hat_Vorrat` | Robot is carrying objects |

## Example Program

```pascal
PROGRAM Laby;

PROCEDURE Suche;
BEGIN
  IF Links_Frei THEN
  BEGIN
    Drehe_Links;
    Vor;
  END ELSE
    IF Vorne_Frei THEN Vor
    ELSE
      IF Rechts_Frei THEN
      BEGIN
        Drehe_Links;
        Drehe_Links;
        Drehe_Links;
        Vor;
      END ELSE
      BEGIN
        Drehe_Links;
        Drehe_Links;
        Vor;
      END;
END;

BEGIN
  WHILE NOT Platz_Belegt DO Suche;
END.
```

## File Types

- `.PAS` - Program source code
- `.NIK` - Compiled bytecode
- `.ROB` - Field/world files (grid layout)

## Keyboard Shortcuts

- `Ctrl-F9` - Compile and run
- `Alt-X` / `Ctrl-Q` - Exit
