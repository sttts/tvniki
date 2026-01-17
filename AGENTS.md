# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

**Issue IDs**: Use descriptive keyword IDs, e.g. `tvniki-port-to-freepascal`, `tvniki-fix-compiler-crash`, not sequential numbers.

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

## Project Overview

tvNiki is a 1996 DOS educational programming environment ported to Free Pascal with Unicode Free Vision. It teaches programming concepts through a robot ("Niki") that navigates a grid field, collecting and placing objects. Students write Pascal-like programs to control the robot.

## Build System

This project uses Free Pascal with a customized UTF-8 Free Vision library (`fv_utf8/`).

To compile:
```bash
make          # Build the niki executable
make clean    # Remove build artifacts
```

Requirements:
- Free Pascal Compiler (fpc) with Turbo Pascal mode support
- macOS or Linux terminal with UTF-8 and mouse support

## Architecture

### Main Components

- **NIKI.PAS** - Entry point, initializes TNikiApplication
- **NIKIAPP.PAS** - Main application class (TNikiApplication), manages windows, menus, and event handling
- **NIKIFELD.PAS** - Field editor (TFeldEditor) and robot simulation (TRobot), handles the visual grid where Niki operates
- **NIKIFLWN.PAS** - Field window (TFieldWindow) with info bar showing robot state
- **NIKICOMP.PAS** - Compilation dialog UI
- **COMPILER.PAS** - Pascal-subset compiler that generates bytecode (.NIK files)
- **INTP.PAS** - Bytecode interpreter (TInterpreter) that executes compiled programs
- **OPCODES.PAS** - Virtual machine opcode definitions
- **TIMER.PAS** - Cross-platform timing using SysUtils (replaces DOS INT 1Ch)

### Free Vision Customizations (fv_utf8/)

The `fv_utf8/` directory contains a UTF-8 enabled fork of Free Vision with these key modifications:

- **views.pas** - 64-bit TDrawBuffer for UTF-8 characters, drag'n'drop screen updates
- **drivers.pas** - Mouse event routing fix (keycode 0 -> evNothing for queued mouse events)
- **keyboard.pp** - SGR 1006 extended mouse protocol parsing
- **mouse.pp** - Mouse mode 1002 (button-event tracking) for drag support

### Compilation Pipeline

1. Source files (.PAS) are compiled by COMPILER.PAS into bytecode (.NIK)
2. The compiler is a recursive descent parser supporting: PROGRAM, PROCEDURE, BEGIN/END, IF/THEN/ELSE, WHILE/DO, REPEAT/UNTIL
3. Built-in commands: VOR (forward), DREHE_LINKS (turn left), NIMM_AUF (pick up), GIB_AB (put down)
4. Built-in functions: VORNE_FREI, LINKS_FREI, RECHTS_FREI, PLATZ_BELEGT, HAT_VORRAT
5. TProgInterpreter (in NIKIFELD.PAS) extends TInterpreter to connect bytecode execution to the robot

### File Types

- `.PAS` - Student program source code
- `.NIK` - Compiled bytecode
- `.ROB` - Field/world files (grid layout with walls and objects)
- `.HLP` - Help file (HILFE.HLP)
- `.CFG` - Configuration (NIKI.CFG)

### Key Classes

- **TNikiApplication** (NIKIAPP.PAS) - Application class, handles menus and windows
- **TFeldEditor** (NIKIFELD.PAS) - Grid editor with run/debug/teach-in modes
- **TRobot** (NIKIFELD.PAS) - Robot state and movement logic
- **TInterpreter** (INTP.PAS) - Base bytecode VM with stack and instruction pointer
- **TProgInterpreter** (NIKIFELD.PAS) - Connects interpreter to robot actions

### Configuration

NIKI.CFG supports: LINES (25/50), BIGHELP (0/1), PROCESS (0/1), VIDMODE (COLOR/BW/MONO), SPEED, DEBUG (0/1)
