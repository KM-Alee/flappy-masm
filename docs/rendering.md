# Rendering and ANSI Architecture

## Rendering objective

The renderer should produce a stable, beautiful frame in ordinary terminals without flicker, tearing, or complicated draw logic.

The guiding principle is:

> Compose the whole frame in memory, encode it once, write it once.

That is the simplest approach that is still excellent for a game of this size.

## Terminal behavior model

The game should use standard virtual terminal behavior:

- enter alternate screen buffer on startup
- hide the cursor while running
- move the cursor explicitly with ANSI sequences
- restore everything on exit, even on failure paths where possible

Core sequences to use:

- alternate screen on: `ESC[?1049h`
- alternate screen off: `ESC[?1049l`
- hide cursor: `ESC[?25l`
- show cursor: `ESC[?25h`
- home cursor: `ESC[H`
- reset style: `ESC[0m`

## Why ANSI/VT is the correct output layer

ANSI/VT output is the only approach that maps naturally to both Linux terminals and modern Windows console hosts. It avoids platform-specific drawing APIs and keeps the rendering model straightforward.

For Windows output, the future runtime should enable:

- `ENABLE_PROCESSED_OUTPUT`
- `ENABLE_VIRTUAL_TERMINAL_PROCESSING`

This is the correct compatibility path for PowerShell and Windows Terminal.

## Frame model

Use a cell grid as the canonical render target.

### Cell structure

Each cell should be represented by a very small struct:

- glyph codepoint
- foreground color
- background color
- style flags if truly needed

Keep it small and predictable. If style flags are unnecessary, omit them.

### Buffers

Version 1 should keep exactly these buffers:

- `cells[]`: the current frame grid
- `outbuf[]`: the encoded ANSI byte stream for the frame

Only add `prev_cells[]` later if profiling proves it worthwhile.

## Recommended drawing approach

### 1. Clear the logical frame

Reset the cell buffer to the default sky background.

### 2. Draw full-scene layers in order

- sky
- distant accents if any
- pipes
- ground
- bird
- particles
- HUD
- overlays

This ordering is easy to reason about and keeps overlap behavior obvious.

### 3. Encode row-major

Walk the grid left-to-right, top-to-bottom. Track the current foreground and background colors while encoding so you only emit SGR changes when necessary.

### 4. Write once

Emit one large write to stdout per frame.

That single-write rule is important. It reduces flicker and makes timing more predictable.

## Visual quality strategy

### Vertical detail

A terminal has coarse geometry, so use it carefully.

Recommended default:

- design around character cells first
- use block glyphs for solid shapes
- use half blocks when they clearly improve vertical smoothness

Do not begin with an overcomplicated sub-cell renderer. Keep the first renderer readable.

### Color tiers

Support three output tiers:

#### Tier 1: truecolor

Use `38;2` and `48;2` SGR sequences when available.

#### Tier 2: 256-color

Map the same palette to stable ANSI 256 values.

#### Tier 3: 16-color fallback

Use a conservative, high-contrast fallback palette.

The game should look best on truecolor terminals but still remain attractive and fully playable on lower tiers.

## Suggested palette direction

This is a planning palette, not a final locked palette.

- sky: bright soft blue
- pipe body: saturated green or cyan-green
- bird: warm yellow with a darker accent
- ground: earthy brown
- HUD text: white or warm white
- score particle: yellow/white
- crash particle: orange/red

The final palette should favor contrast and calm readability over excessive saturation.

## Resize behavior

The renderer must respond cleanly to terminal size changes.

### Rules

- read terminal size at startup
- re-check periodically or on resize notifications
- rebuild frame dimensions when size changes
- if too small, show a dedicated warning screen

Never let the game silently render out of bounds.

## Frame pacing

The renderer should support a fixed simulation step and a separate frame scheduler.

Recommended initial target:

- simulation: `60 Hz`
- presentation: `60 Hz` when possible

If a terminal cannot keep up, correctness matters more than flashy effects. Slowdowns should not corrupt terminal state.

## Best-practice constraints

To keep the renderer elegant:

- no per-object stdout writes
- no scattered cursor jumps for ordinary drawing
- no terminal scrolling during gameplay
- no assumptions about a fixed terminal font
- no hidden dependency on a specific shell theme

## Windows and Linux split

Output should remain conceptually unified, but setup differs:

### Linux

- write UTF-8 + ANSI bytes directly to stdout
- use raw terminal mode for input

### Windows

- enable UTF-8 console behavior
- enable VT processing on the output handle
- keep output ANSI-driven once enabled

The renderer API should not know which platform prepared the terminal. It should only receive a terminal descriptor and a writable output sink.
