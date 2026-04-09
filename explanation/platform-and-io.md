# Platform, Input, And I/O

## Why there are Linux and Windows variants

The game wants one shared gameplay core, but terminals are not configured the same way on Linux and Windows.

So the project splits platform responsibilities into separate files while preserving shared rules everywhere else.

## Terminal setup on Linux

`terminal.asm` is responsible for:

- verifying stdin and stdout are TTYs
- reading the current terminal mode
- switching stdin into raw mode
- disabling canonical input and echo
- writing the alternate-screen and cursor-hide escape sequences
- restoring everything on exit

The Linux version also registers signal handlers for resize and termination.

## Terminal setup on Windows

`terminal_win.asm` does equivalent work using Windows console APIs.

It:

- obtains console handles
- reads the current console mode
- enables virtual terminal processing
- writes the same ANSI startup sequences
- restores the saved console mode on exit

The important idea is that output is still ANSI-driven after setup. The platform layer only prepares the console.

## Shared layout rules

Both terminal backends now call `RecomputeLayout` from `gameplay.asm` after updating `term_cols` and `term_rows`.

That means the rules for:

- minimum size detection
- bird column placement
- ground row
- pipe gap sizing
- pipe spacing

live in one place instead of being duplicated across both backends.

This is one of the cleanest simplifications in the current codebase.

## Input on Linux

`input.asm` uses non-blocking reads from stdin.

It polls for available input, reads any pending bytes, and then walks through them one by one.

Special handling exists for escape sequences so the up arrow can be treated as a flap key.

Recognized actions include:

- flap
- pause
- restart
- quit

The file translates bytes into actions, then calls shared helpers like `HandleFlapKey` and `HandlePauseKey`.

## Input on Windows

`input_win.asm` uses `_kbhit` and `_getch`.

The logic is conceptually the same as Linux:

- detect whether input is waiting
- read key codes
- special-case the up arrow
- translate known keys into shared actions

Again, the important point is that the meanings of those actions are not duplicated. The file only handles acquisition and classification.

## Persistence

Best score persistence is intentionally tiny.

The game stores a 4-byte integer in `.flappy_highscore.bin`.

The shared persistence helpers:

- open the file
- read or write exactly 4 bytes
- close the file

That minimal format is a strength. It is easy to inspect and hard to misunderstand.

## Sound effects

This project does not include a heavyweight audio system.

Instead, it stores shell commands as strings and dispatches them through `system`.

That makes sound support a best-effort convenience, not a deep engine subsystem.

Linux and Windows differ mainly in the command string and calling convention glue.

## Timing and sleeping

Timing is platform-specific because clock APIs differ.

### Linux utility backend

Uses:

- `clock_gettime`
- `nanosleep`

### Windows utility backend

Uses:

- `QueryPerformanceCounter`
- `QueryPerformanceFrequency`
- `Sleep`

Both implementations return nanosecond-like timing values to the shared game loop so the loop logic itself can remain unchanged.

## Why these abstractions are enough

The platform layer is intentionally thin.

It only needs to answer a few questions for the game:

- what keys were pressed?
- how big is the terminal?
- what time is it?
- how do I sleep?
- how do I write bytes?

That is enough to support the rest of the project without pulling OS details into the gameplay files.