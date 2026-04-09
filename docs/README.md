# Terminal Flappy Bird

A terminal-first Flappy Bird in **x86-64 MASM-style assembly**, rendered with
ANSI/VT escape codes and designed for clean, responsive gameplay in any modern
terminal emulator.

## Project structure

```text
flappy-asm/
  include/
    config.inc      Game constants (physics, sizing, colors)
    linux.inc       Linux ABI constants and libc declarations
    game.inc        Shared data and cross-module procedure declarations
  src/
    main.asm        Entry point, main loop, all shared data definitions
    terminal.asm    Terminal setup/restore, signals, geometry
    input.asm       Non-blocking input polling and key dispatch
    gameplay.asm    Shared state helpers and responsive layout rules
    physics.asm     Bird physics, pipe logic, collision, game state
    render.asm      Background, pipes, ground, bird, HUD, overlays
    util.asm        Timing, RNG, file I/O, string formatting
  explanation/
    *.md            Newbie-focused walkthroughs of each major system
  docs/
  build/
  Makefile
  build.sh
  run.sh
  debug.sh
```

## Design pillars

### 1. Terminal-native, not a GUI port

Full-screen ANSI color rendering with clean setup/restore of terminal state.
Fixed-timestep game loop at 60 fps with single-write frame output.

### 2. MASM-style source, Linux-first workflow

Assembled with `uasm -elf64`, linked with `gcc -no-pie`. The source uses Intel
syntax and MASM-compatible directives in a disciplined portable subset.

### 3. Elegant simplicity

Plain data layouts, clear module boundaries, predictable control flow. Every
module has a single clear responsibility.

### 4. Visual polish by composition

- Smooth blue sky gradient (deep blue at top, lighter toward bottom)
- Solid color-block ground (green grass strip over brown earth)
- Solid green pipes with lighter cap rows
- Multi-cell ASCII bird sprite: `__()>` / ` \_)`
- Drifting white block clouds
- Score with contrasting background, best score at top-right
- Clean overlay panels for title, pause, and game-over states

## Building

```bash
make            # release build
make debug      # debug build (-g -O0)
make run        # build and run
make gdb        # build debug and launch gdb
make clean      # remove build artifacts
```

Or use the shell scripts: `./build.sh`, `./run.sh`, `./debug.sh`.

## Controls

| Key                    | Action              |
|------------------------|----------------------|
| `Space` / `W` / `Up`  | Flap                |
| `P`                    | Pause / Unpause     |
| `R`                    | Restart after crash  |
| `Q` / `Esc`           | Quit                |

## Feature summary

- Classic flap physics with smooth parabolic arcs
- Procedurally generated pipes with adaptive gap sizing
- Score and high-score persistence (`.flappy_highscore.bin`)
- Start, play, pause, crash, and restart states
- ANSI 256-color rendering with single-write frames
- Terminal resize handling with minimum size enforcement (80×24)
- Adaptive layout scaling for different terminal sizes
- Debug overlay via `FLAPPY_DEBUG=1` environment variable
