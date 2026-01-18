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
bd create --id <id> --title "Title" --body "Description"  # Create new issue
```

## Testing with tmux

When running the application for testing, use tmux sessions named after your current task:

```bash
tmux new-session -d -s <task-id> -x 100 -y 30 './niki'
tmux send-keys -t <task-id> ...
tmux capture-pane -t <task-id> -p
tmux kill-session -t <task-id>
```

## Worktree Workflow

Merge from worktree into main checkout, close issue, and clean up:
```bash
cd ../tvniki-2026
git merge <branch>
bd close <task-id>
git worktree remove ../<worktree-dir>
git branch -d <branch>
```

**Always close the issue immediately after merging** - don't wait to be asked.

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

## Debugging Crashes

On crash, tvNiki switches back to the main terminal screen and displays the error with stack addresses:
```
An unhandled exception occurred at $000000018CA2E2F4:
EAccessViolation: Access violation
  $000000018CA2E2F4
  $0000000100E58C58
  ...
```

To decode addresses to file:line, use lldb:
```bash
lldb ./niki -o "image lookup -a 0x0000000100E58C58" -o quit
```

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
