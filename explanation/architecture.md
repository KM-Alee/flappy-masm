# Architecture

## Big picture

The project is organized around a simple rule:

> Platform code gathers information. Shared code decides what the game means. Rendering turns game state into a frame.

That split matters because it keeps the code portable and easy to reason about.

## Main modules

### `main.asm`

This is the anchor of the whole program.

It does two jobs:

1. Defines every shared global variable.
2. Runs the master loop.

Because every global is defined here, there is exactly one owner for the game's shared state. Other files only declare those globals as external symbols through `include/game.inc`.

### `terminal.asm` and `terminal_win.asm`

These files are the platform shells.

They do not contain gameplay rules. They only:

- configure the terminal or console
- restore the terminal on exit
- query terminal size
- register signal or control handlers

This is the correct place for OS-specific details because they are not part of the game itself.

### `input.asm` and `input_win.asm`

These files read pending input and classify keys.

They do not decide the meaning of pause, flap, or restart by duplicating game logic anymore. They now pass those actions into shared helpers from `gameplay.asm`.

### `gameplay.asm`

This file exists to keep small but important state transitions in one place.

It owns shared helpers for:

- flap behavior
- pause toggling
- restart handling
- responsive layout recomputation from terminal size

This is a useful simplification because both Linux and Windows were doing the same work in separate files.

### `physics.asm`

This file contains the simulation.

It answers questions like:

- How does gravity change velocity?
- How do pipes move?
- When does the score increase?
- What counts as a collision?
- What happens when the run ends?

This is the heart of the game rules.

### `render.asm`

This file turns game state into pixels in the only format the game has: terminal cells.

The renderer does not ask the terminal to draw each object directly. Instead, it writes into a memory buffer representing the screen, then encodes that buffer into one ANSI output stream.

That is the main rendering design choice in the project.

### `util.asm` and `util_win.asm`

These files are mixed support layers.

They handle:

- clocks and sleeping
- RNG seeding
- score file I/O
- string and number formatting
- sound shell-command dispatch

The platform-specific parts stay in the `.asm` files, while the identical formatting and persistence routines now live in `include/util_shared.inc`.

## Shared declarations

### `include/config.inc`

This file contains constants.

Examples:

- terminal limits
- state IDs
- physics values
- buffer sizes
- structure offsets

This is the “knob” file of the project.

### `include/game.inc`

This file is the contract between modules.

It declares:

- global data symbols defined in `main.asm`
- procedure symbols exported by the other modules

If you want to know how files communicate, this is one of the first files to read.

## Dependency direction

The dependency flow is intentionally simple:

1. `main.asm` owns the data.
2. Other modules import the shared data through `game.inc`.
3. Platform files do OS work.
4. Shared gameplay files consume plain state.
5. The renderer consumes final game state and produces a frame.

What does not happen is equally important:

- `physics.asm` does not perform terminal syscalls.
- `render.asm` does not read the keyboard.
- `input.asm` does not encode ANSI output.

That separation is why the project stays readable.

## Why globals are acceptable here

In many languages, global state is often a warning sign. In this program, it is a deliberate tradeoff.

Reasons it works well here:

- the program is small and single-threaded
- there is one clear owner for every global definition
- the data model is plain and finite
- the module boundaries are still strong even though the storage is shared

In other words, the danger is not “globals exist.” The danger would be “any file mutates anything without discipline.” This codebase avoids that by giving each module a narrow responsibility.

## Reading strategy

If you want to understand the whole architecture quickly, read files in this order:

1. `include/config.inc`
2. `include/game.inc`
3. `main.asm`
4. `gameplay.asm`
5. `physics.asm`
6. `render.asm`
7. `terminal.asm` or `terminal_win.asm`
8. `input.asm` or `input_win.asm`
9. `util.asm` or `util_win.asm`

That order moves from shared concepts to concrete systems.