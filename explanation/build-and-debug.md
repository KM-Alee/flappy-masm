# Build And Debug

## Linux build path

The normal Linux build is driven by `Makefile`.

The key steps are:

1. assemble each `.asm` file with `uasm -elf64`
2. place object files under `build/linux`
3. link them with `gcc -no-pie`
4. produce `build/flappy-term`

The shell wrappers `build.sh`, `run.sh`, and `debug.sh` are convenience front ends around the Make targets.

## Windows build path

The Windows build is described by `Makefile.windows` and `windows/build.ps1`.

The important point is that the Windows build swaps in these source files:

- `input_win.asm`
- `terminal_win.asm`
- `util_win.asm`
- `windows_crt.asm`

while still sharing:

- `main.asm`
- `gameplay.asm`
- `physics.asm`
- `render.asm`

This is exactly the portability strategy the architecture was aiming for.

## Why `windows_crt.asm` exists

On Windows, some C runtime calls use names like `_write` and `_open` and different calling conventions.

`windows_crt.asm` provides thin wrappers so the rest of the code can keep using neutral names like:

- `write`
- `read`
- `open`
- `close`

That is a small but very effective compatibility layer.

## Debug build

On Linux:

- `make debug`
- `./debug.sh`
- `make gdb`

The project is small enough that traditional debugger stepping works well, especially in:

- `main.asm`
- `UpdateGame`
- `RenderFrame`

## What to test after a refactor

For this codebase, the most important checks are:

1. Does it assemble and link?
2. Does the game launch in a real terminal?
3. Can it reach the title screen without corrupting terminal state?
4. Do pause, restart, and quit still work?
5. Does resize handling still recompute layout correctly?

That is why the simplification work in this session was validated by building and launching after each major step.

## Good places to inspect while debugging

### If the game does not start

Check:

- `SetupTerminal`
- `InstallProcessHooks`
- `UpdateTerminalGeometry`
- startup calls in `main`

### If controls behave incorrectly

Check:

- `PollInput`
- `HandleFlapKey`
- `HandlePauseKey`
- `HandleRestartKey`

### If motion feels wrong

Check:

- `GRAVITY_FP`
- `FLAP_VEL_FP`
- `MAX_FALL_FP`
- `UpdateGame`

### If visuals look wrong

Check:

- `FillRect`
- `PutCell`
- `RenderFrame`
- `EncodeAndPresent`

## How to learn from the build system

A useful exercise is to follow one source file from source to executable:

1. locate it in `SRCS`
2. find its object file path in `OBJS`
3. see how it is assembled
4. see how all objects are linked together

That teaches not just this project, but also how assembly projects are usually organized in practice.

## Final lesson

The build system for this repository is intentionally straightforward.

That simplicity is part of the teaching value of the codebase. You can see clearly:

- what gets assembled
- what gets linked
- what is platform-specific
- what is shared

Nothing important is hidden behind a giant framework.