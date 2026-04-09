# Platform and Build Strategy

## Key decision

The project will be written in a **MASM-compatible assembly style**, but development will start on Linux using `uasm`.

This is the right choice because:

- you are developing on Linux today
- `uasm` is already available on your machine
- `uasm` supports both `-elf64` and `-win64`
- we can keep the source close to MASM while still producing native Linux and Windows binaries

## What “MASM” means for this project

For this project, “MASM” should mean:

- Intel syntax
- MASM-style directives and macros
- disciplined use of a portable subset
- source layout that does not depend on one vendor's assembler quirks

That keeps the project practical.

### Important reality

`ml64.exe` is a Windows tool and is not the best primary path for Linux-native development. Therefore:

- **Linux-first builds** should use `uasm`
- **Windows builds** can use `uasm` or `ml64.exe` for the Windows target where compatibility allows

This preserves the spirit of MASM while keeping your workflow sane.

## Validated current Linux environment

The current workstation already has:

- `wine`
- `x86_64-w64-mingw32-g++`
- `uasm`
- `make`
- `cmake`

That means we can begin development on this Linux machine without changing the reference game.

## Current project layout

```text
flappy-asm/
  include/
    config.inc        Game constants and physics tuning
    linux.inc         Linux syscall constants and libc declarations
    game.inc          Shared cross-module declarations (data + procedures)
  src/
    main.asm          Entry point, main loop, all shared data
    terminal.asm      Terminal setup/restore, signals, geometry
    input.asm         Non-blocking input and key dispatch
    gameplay.asm      Shared state helpers and layout recomputation
    physics.asm       Bird physics, pipes, collision, game state
    render.asm        All drawing: background, pipes, bird, HUD, overlays
    util.asm          Timing, RNG, file I/O, string formatting
  docs/
  build/
  Makefile
```

## Platform architecture

## Shared core

Everything below should be shared logic:

- bird physics
- pipe generation
- collision
- score
- state machine
- scene composition into cells

## Platform-specific layer

Only the thin platform layer should differ:

- terminal setup and restore
- input acquisition
- time/sleep functions
- file path details for high score storage
- program entry point and ABI glue

That split keeps the interesting game logic platform-neutral.

## Linux development plan

Linux should be the first implementation target because it is the current workstation and the easiest place to iterate quickly.

### Linux responsibilities

- switch stdin to raw non-canonical mode
- disable echo
- read non-blocking keyboard input
- get terminal size
- write UTF-8/ANSI to stdout
- restore terminal state on exit

### Linux toolchain

Preferred package baseline on Arch:

```bash
sudo pacman -S base-devel uasm mingw-w64-gcc wine
```

If `uasm` is installed from AUR or otherwise already present, that is fine.

### Linux binary path

Future Linux builds should look like this conceptually:

```bash
uasm -q -elf64 -Fo build/linux/main.o src/platform/linux/main.asm
uasm -q -elf64 -Fo build/linux/game_state.o src/core/game_state.asm
gcc -o build/flappy-term build/linux/*.o
```

Exact link details can wait until implementation, but this is the correct direction.

## Windows support plan

Windows output should still use ANSI/VT rather than classic screen-buffer drawing APIs.

### Windows runtime setup

At startup, the Windows platform layer should:

- get console input and output handles
- enable UTF-8 if needed
- enable `ENABLE_VIRTUAL_TERMINAL_PROCESSING` on output
- disable line-buffered console input behavior as needed
- choose a reliable keyboard input path

### Input recommendation

For maximum robustness on Windows, prefer a thin Windows-specific input path instead of forcing VT input for everything.

Recommended approach:

- use ANSI/VT for output
- use a reliable Windows console input API for keyboard events

This keeps output cross-platform while avoiding fragile input behavior.

### Windows build paths

Two supported options should exist:

#### Option A: Linux cross-build for Windows

Use Linux as the authoring environment and produce a Windows executable:

```bash
uasm -q -win64 -Fo build/win64/main.obj src/platform/windows/main.asm
x86_64-w64-mingw32-gcc -o build/flappy-term.exe build/win64/*.obj
```

#### Option B: Native Windows developer workflow

Allow Windows contributors to build with either:

- `uasm`
- `ml64.exe` plus the normal Microsoft linker toolchain, if the Windows-target source stays inside a compatible subset

## Compatibility rules

To keep the source genuinely portable across both targets:

- avoid assembler-specific magic unless absolutely necessary
- isolate ABI differences in separate platform files
- keep macros small and explicit
- never mix platform syscalls into shared game files
- keep Unicode handling centralized

## Terminal support target

The practical support target is:

- Linux terminal emulators with ANSI + UTF-8
- Windows Terminal
- PowerShell hosted in modern Windows console environments

The project should degrade gracefully if:

- only 16 colors are available
- Unicode glyph quality is poor
- the terminal is too small

## Out-of-scope choices

Avoid these for the first version:

- ncurses
- PDCurses
- graphics libraries
- Win32 screen-buffer rendering APIs
- audio systems that complicate portability

The point of this project is that the assembly owns the terminal directly.
