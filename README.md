# tvNiki

[![Build](https://github.com/sttts/tvniki-2026/actions/workflows/build.yml/badge.svg)](https://github.com/sttts/tvniki-2026/actions/workflows/build.yml)

An educational programming environment where students control a robot named "Niki" through a Pascal-like language. Originally created in **1996** for DOS, now ported to Free Pascal with UTF-8 support in **2026** — 30 years of teaching programming!

![tvNiki Screenshot](screenshot.png)

## Overview

tvNiki teaches programming fundamentals through a simple robot simulation. Niki moves on a grid, collects and places objects, and navigates around walls. Students write programs using basic control structures (IF/THEN/ELSE, WHILE/DO, REPEAT/UNTIL) and procedures.

## Installation

### macOS (Homebrew)

```bash
brew install --head sttts/tvniki-2026/tvniki
```

This installs both `tvniki` (the GUI) and `nikic` (the command-line compiler).

### Linux (Pre-built Binaries)

Download from [GitHub Releases](https://github.com/sttts/tvniki-2026/releases):

- `tvniki-linux-x86_64.tar.gz` - Linux x86_64
- `tvniki-linux-arm64.tar.gz` - Linux ARM64

```bash
tar xzf tvniki-linux-x86_64.tar.gz
cd tvniki-linux-x86_64
./tvniki
```

### Building from Source

```bash
# macOS
brew install fpc

# Debian/Ubuntu
sudo apt-get install fpc

# Clone and build
git clone --recursive https://github.com/sttts/tvniki-2026.git
cd tvniki-2026
make
```

## Running

```bash
./tvniki              # Start with empty editor
./tvniki program.pas  # Load a program file
./tvniki field.rob    # Load a field file
```

### Command-Line Compiler

```bash
./nikic program.pas           # Compile to program.nik
./nikic -o output.nik src.pas # Specify output file
./nikic -d program.pas        # Include debug info
```

## Robot Commands

Both English and German commands are supported:

| English | German | Description |
|---------|--------|-------------|
| `Forward` | `Vor` | Move forward one cell |
| `Turn_Left` | `Drehe_Links` | Turn left 90 degrees |
| `Pick_Up` | `Nimm_Auf` | Pick up object from current cell |
| `Put_Down` | `Gib_Ab` | Place object on current cell |

## Sensor Functions

| English | German | Returns true when... |
|---------|--------|---------------------|
| `Front_Clear` | `Vorne_Frei` | Cell ahead is free |
| `Left_Clear` | `Links_Frei` | Cell to the left is free |
| `Right_Clear` | `Rechts_Frei` | Cell to the right is free |
| `Space_Occupied` | `Platz_Belegt` | Current cell has an object |
| `Has_Supply` | `Hat_Vorrat` | Robot is carrying objects |

## Example Program

```pascal
PROGRAM Laby;

PROCEDURE Search;
BEGIN
  IF Left_Clear THEN
  BEGIN
    Turn_Left;
    Forward;
  END ELSE
    IF Front_Clear THEN Forward
    ELSE
      IF Right_Clear THEN
      BEGIN
        Turn_Left;
        Turn_Left;
        Turn_Left;
        Forward;
      END ELSE
      BEGIN
        Turn_Left;
        Turn_Left;
        Forward;
      END;
END;

BEGIN
  WHILE NOT Space_Occupied DO Search;
END.
```

## File Types

- `.pas` - Program source code
- `.nik` - Compiled bytecode
- `.rob` - Field/world files (grid layout)

## Keyboard Shortcuts

- `Ctrl-F9` - Compile and run
- `Alt-F9` - Compile only
- `Ctrl-F8` - Single step (debug mode)
- `Ctrl-F2` - Reset/stop program
- `Alt-X` / `Ctrl-Q` - Exit

## Disassemble Window

The disassemble window (Compiler → Disassemble) shows the compiled bytecode with human-readable descriptions:

```
-->   7  DBG #5      Source line 5
     10  CLF         Check left free
     11  JNC 18      Jump if false to 18
     14  TURN        Turn left
     15  GO          Go forward
```

Features:
- Auto-updates after compilation
- Current execution line highlighted in blue with `-->` marker
- Shows instruction pointer (IP) and carry flag in the status bar
- Follows execution during run and single-step debugging

## Localization

tvNiki automatically loads translations based on the `LANG` environment variable. Supported languages: German (default), English, Spanish, French, Italian, Dutch, Portuguese, Norwegian, Swedish, Icelandic.

```bash
LANG=en_US ./tvniki   # Run in English
LANG=es_ES ./tvniki   # Run in Spanish
```
