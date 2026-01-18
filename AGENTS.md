# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

**Issue IDs**: Use descriptive keyword IDs, e.g. `tvniki-port-to-freepascal`, `tvniki-fix-compiler-crash`, not sequential numbers.

## Quick Reference

```bash
bd ready --pretty     # Find available work (○ open, ◐ in_progress)
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
bd create --id <id> --title "Title" --body "Description"  # Create new issue
bd comments add <id> "Comment text"  # Add comment to issue
```

## Starting Work

**Always** create a worktree when starting work on an issue:

```bash
bd update <id> --status in_progress
bd worktree create worktrees/<id>
cd worktrees/<id>
```

**Note:** `bd ready` shows both open and in_progress issues. When presenting results (e.g., for "What's next?"), always show two separate sections:

```
In progress:
- tvniki-some-task - Description

Available to start:
- tvniki-other-task - Description
```

Only suggest or choose an in-progress issue when the user explicitly asks to continue one.

## Testing with tmux

When running the application for testing, use tmux sessions named after your current task:

```bash
tmux new-session -d -s <task-id> -x 100 -y 30 './niki'
tmux send-keys -t <task-id> ...
tmux capture-pane -t <task-id> -p
tmux kill-session -t <task-id>
```

**Tip**: Pass a .pas file as command-line argument to load it directly: `./niki laby.pas`

## Worktree Workflow

Use `bd worktree` (not `git worktree` directly) to ensure beads configuration is shared:

```bash
bd worktree create worktrees/<task-id>    # Create worktree with beads redirect
cd worktrees/<task-id>
# ... do work ...
```

Merge from worktree into main checkout, close issue, and clean up:
```bash
cd /Users/sts/Quellen/tvniki-2026
git merge <branch>
bd close <task-id>
git worktree remove worktrees/<task-id>
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

- **NIKI.pas** - Entry point, initializes TNikiApplication
- **NIKIAPP.pas** - Main application class (TNikiApplication), manages windows, menus, and event handling
- **NIKIFELD.pas** - Field editor (TFeldEditor) and robot simulation (TRobot), handles the visual grid where Niki operates
- **NIKIFLWN.pas** - Field window (TFieldWindow) with info bar showing robot state
- **NIKICOMP.pas** - Compilation dialog UI
- **COMPILER.pas** - Pascal-subset compiler that generates bytecode (.nik files)
- **INTP.pas** - Bytecode interpreter (TInterpreter) that executes compiled programs
- **OPCODES.pas** - Virtual machine opcode definitions
- **TIMER.pas** - Cross-platform timing using SysUtils (replaces DOS INT 1Ch)

### Free Vision Customizations (fv_utf8/)

**Avoid changing fv_utf8** unless necessary. If you do modify it and merge your branch back into master, don't forget to also transfer the fv_utf8 changes to the main fv_utf8 repository.

The `fv_utf8/` directory contains a UTF-8 enabled fork of Free Vision with these key modifications:

- **views.pas** - 64-bit TDrawBuffer for UTF-8 characters, drag'n'drop screen updates
- **drivers.pas** - Mouse event routing fix (keycode 0 -> evNothing for queued mouse events)
- **keyboard.pp** - SGR 1006 extended mouse protocol parsing
- **mouse.pp** - Mouse mode 1002 (button-event tracking) for drag support

### Compilation Pipeline

1. Source files (.pas) are compiled by COMPILER.pas into bytecode (.nik)
2. The compiler is a recursive descent parser supporting: PROGRAM, PROCEDURE, BEGIN/END, IF/THEN/ELSE, WHILE/DO, REPEAT/UNTIL
3. Built-in commands: VOR (forward), DREHE_LINKS (turn left), NIMM_AUF (pick up), GIB_AB (put down)
4. Built-in functions: VORNE_FREI, LINKS_FREI, RECHTS_FREI, PLATZ_BELEGT, HAT_VORRAT
5. TProgInterpreter (in NIKIFELD.pas) extends TInterpreter to connect bytecode execution to the robot

### File Types

- `.pas` - Student program source code
- `.nik` - Compiled bytecode
- `.rob` - Field/world files (grid layout with walls and objects)
- `.HLP` - Help file (HILFE.HLP)
- `.CFG` - Configuration (NIKI.CFG)

### Key Classes

- **TNikiApplication** (NIKIAPP.pas) - Application class, handles menus and windows
- **TFeldEditor** (NIKIFELD.pas) - Grid editor with run/debug/teach-in modes
- **TRobot** (NIKIFELD.pas) - Robot state and movement logic
- **TInterpreter** (INTP.pas) - Base bytecode VM with stack and instruction pointer
- **TProgInterpreter** (NIKIFELD.pas) - Connects interpreter to robot actions

### Configuration

NIKI.CFG supports: LINES (25/50), BIGHELP (0/1), PROCESS (0/1), VIDMODE (COLOR/BW/MONO), SPEED, DEBUG (0/1)
