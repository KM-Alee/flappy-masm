# Data Layout And Memory Model

## Where the shared state lives

All shared data is defined in `main.asm` inside the `.data` section.

That includes:

- strings
- palette data
- OS scratch buffers
- render buffers
- scalar game state
- pipe arrays
- 64-bit timing and RNG values

Other modules do not define their own copies of these values. They import them through `externdef` declarations in `include/game.inc`.

## Why this matters

Assembly becomes much easier to read when you know whether a value is:

- a register-only temporary
- a shared global scalar
- an array entry
- a buffer pointer

This project is disciplined about that distinction.

## Important scalar globals

### Terminal state

- `term_cols`
- `term_rows`
- `small_terminal`
- `terminal_active`
- `resize_requested`
- `exit_requested`

These describe the runtime environment, not the gameplay itself.

### Game state

- `game_state`
- `bird_y`
- `bird_velocity`
- `score_value`
- `best_score`
- `frame_counter`

These are the core pieces of state that change during play.

### Layout state

- `pipe_gap_height`
- `pipe_spacing`
- `bird_column`
- `ground_top_row`

These values are derived from terminal size. They are recomputed by `RecomputeLayout` in `gameplay.asm`.

## Pipe arrays

Pipes are stored as three parallel arrays:

- `pipes_x`
- `pipes_gap_y`
- `pipes_scored`

This is an old but extremely effective data-oriented layout.

Instead of a “pipe object,” each pipe index represents one logical entity spread across three arrays.

For pipe `i`:

- `pipes_x[i]` is the horizontal position
- `pipes_gap_y[i]` is the top row of the gap
- `pipes_scored[i]` says whether the player has already received the point for passing it

This is efficient and very readable in assembly because each array has one obvious meaning.

## Fixed-point numbers

The bird position and velocity are stored in 8.8 fixed-point format.

That means:

- the high 24 bits act like the integer portion
- the low 8 bits act like the fractional portion

Examples:

- shifting right by 8 converts to screen rows
- shifting left by 8 converts from integer rows to fixed-point

Why use this?

- it gives smoother movement than pure integers
- it avoids floating-point complexity
- it is easy to clamp and add in assembly

This is one of the most educational design choices in the whole project.

## Buffers

### `cell_buffer`

This is the canonical frame buffer.

Each cell uses `CELL_SIZE` bytes and stores:

- glyph
- foreground color
- background color

The renderer writes the entire scene here first.

### `out_buffer`

This buffer holds the final encoded ANSI byte stream.

The encoder walks the cell buffer row by row, emits color changes only when needed, writes glyphs, then performs one final `write` call.

### Scratch buffers

The project also keeps small reusable work buffers such as:

- `number_buffer`
- `number_reverse`
- `debug_buffer`
- `input_buffer`
- `clock_buffer`
- `sleep_buffer`

These avoid dynamic allocation and keep data lifetimes obvious.

## Strings in memory

Most strings are plain null-terminated byte arrays.

Examples include:

- UI text like `title_line_1`
- ANSI sequence fragments like `home_sequence`
- sound shell commands
- high score file path

This keeps formatting code simple because all string helpers only need to understand one representation.

## Procedure declarations as a memory map

One subtle but useful feature of `include/game.inc` is that it doubles as a mental map of the whole program.

When you read the `externdef` list, you learn:

- which data is globally shared
- which procedures are cross-module entry points
- which modules are meant to be called by others

For a beginner, this file is almost like a manual header file for the whole game.

## What to pay attention to while reading assembly

When a procedure starts, ask three questions:

1. Which globals does it read?
2. Which globals does it write?
3. Which values are just temporary register calculations?

If you answer those correctly, most of the function becomes much easier to follow.