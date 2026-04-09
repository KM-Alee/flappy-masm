# Rendering System

## Core idea

The renderer follows one simple rule:

> Draw everything into memory first. Convert that memory into ANSI text second. Write it once at the end.

This is the key to stable terminal rendering.

## Why not draw directly to the terminal?

If each game object wrote escape sequences and glyphs directly to stdout, the renderer would become:

- harder to reason about
- more flickery
- more dependent on output order bugs
- harder to port cleanly

The cell-buffer approach avoids that.

## Frame composition order

`RenderFrame` calls the render passes in this order:

1. background
2. pipes
3. ground
4. bird
5. HUD
6. overlays
7. debug overlay if enabled
8. ANSI encoding and presentation

That order makes overlap rules obvious. Later layers visually sit on top of earlier layers.

## The cell buffer

Each screen cell stores a packed record with:

- glyph byte
- foreground color byte
- background color byte

The project uses `CELL_SIZE` bytes per cell and stores all cells in `cell_buffer`.

The screen is treated as a `MAX_COLS x MAX_ROWS` grid, even if the active terminal is smaller. Active drawing is clipped against `term_cols` and `term_rows`.

## Drawing primitives

The low-level drawing helpers are the most important part of `render.asm`.

### `FillRect`

Fills a rectangle in the cell buffer using a pre-packed cell value.

It also clips to the active screen bounds.

### `FillSolidRect`

This helper was added during simplification.

It packs a solid color block using a space glyph with matching foreground and background colors, then forwards to `FillRect`.

This is useful because many visual elements are really colored rectangles, not text.

### `PutCell`

Writes one cell at a specific position.

This is used for the bird and text, where individual glyph choice matters.

### `DrawTextAt` and `DrawTextCentered`

These helpers render null-terminated strings into the cell buffer.

They do not print directly to the terminal. They still operate through `PutCell`, which preserves the “render to memory first” rule.

## Background rendering

`RenderBackground` fills each row with a sky color from `sky_palette`.

Then it draws:

- the sun
- drifting layered clouds

Clouds are built from several overlapping white and near-white rectangles. This is a good example of how terminal art often works better by composition than by trying to force detailed glyph art everywhere.

## Ground rendering

`RenderGround` draws the last few rows as:

- one bright green grass strip
- brown earth rows below it

This is visually simple, but it works well because the game needs strong contrast more than detail.

## Pipe rendering

`RenderPipes` uses two colors:

- dark green body
- lighter green caps

Each pipe pair is really four rectangles:

1. upper body
2. upper cap
3. lower cap
4. lower body

This is enough to make the shapes readable without overcomplicating the art.

## Bird rendering

The bird is drawn as a small hand-built ASCII sprite over three rows.

The code computes a pose from `frame_counter`, then places glyphs row by row with `PutCell`.

Important details:

- the bird uses the sky color of each row as its background
- the pose changes by frame bucket
- dead state uses a duller palette

Even though the bird art is tiny, it still follows the same rendering rules as everything else.

## HUD and overlays

The HUD shows:

- current score at the top center
- best score at the top right when present

Overlays include:

- title screen card
- pause card
- game-over card
- size warning screen

These are built from `DrawPanel`, `FillSolidRect`, and centered text helpers.

## ANSI encoding

The last step happens in `EncodeAndPresent`.

It:

1. writes the home-cursor escape sequence into `out_buffer`
2. scans the cell buffer row by row
3. emits a new ANSI color sequence only when foreground or background changes
4. writes each glyph byte
5. inserts line breaks between rows
6. appends a reset-style sequence
7. performs one final `write`

The optimization here is small but important: color changes are tracked, so the encoder does not emit redundant ANSI codes for every cell.

## Why the renderer is deterministic

Given the same:

- terminal size
- frame counter
- pipe positions
- bird state
- score state

the renderer will generate the same cell buffer and the same final ANSI stream.

That determinism is valuable because it makes visual bugs much easier to isolate.

## What to study first in `render.asm`

If the file feels large, focus on these procedures first:

1. `RenderFrame`
2. `FillRect`
3. `PutCell`
4. `EncodeAndPresent`
5. `RenderBackground`
6. `RenderPipes`

Once those make sense, the rest of the file mostly becomes special-case scene composition.