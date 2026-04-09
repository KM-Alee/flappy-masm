# Implementation Roadmap and Quality Rules

## Completed stages

### Stage 1: platform shell ✓

- Alternate screen mode with cursor hiding
- Raw terminal input without Enter
- Clean terminal restore on exit (including atexit handler)
- Signal handling for SIGINT, SIGTERM, SIGHUP, SIGQUIT, SIGWINCH

### Stage 2: fixed loop and timing ✓

- Fixed timestep at 60 fps (16.67ms per tick)
- Accumulator-based update loop (up to 5 updates per frame)
- Frame pacing with nanosleep
- Graceful exit on signals
- Terminal resize detection and geometry recomputation

### Stage 3: cell renderer ✓

- Cell buffer (glyph + fg + bg per cell)
- Row-major ANSI 256-color encoder with color-change optimization
- Single-write frame output to eliminate flicker
- Full-screen rendering with clipping

### Stage 4: gameplay core ✓

- Bird physics with smooth parabolic arcs (tuned gravity/flap)
- Flap input from Space, W, and Up Arrow
- Pipe generation with random gap placement
- Pipe scrolling with recycling
- Floor and ceiling collision
- Pipe collision detection
- Score tracking and increment on pipe pass
- Game over state with fall animation
- High-score persistence to `.flappy_highscore.bin`
- Start, running, paused, and dead game states

### Stage 5: polish ✓

- Clean blue sky gradient background
- Multi-cell bird sprite (__()> / \\_)) in yellow
- Solid color-block ground (green grass + brown earth)
- Solid green pipes with lighter cap rows
- Drifting white block clouds
- Score display with contrasting background
- Best score shown at top-right during gameplay
- Best score shown in game-over overlay
- Overlay panels for title, pause, and game-over
- Adaptive terminal sizing (pipe gap, spacing, bird position)
- Terminal minimum size enforcement (80×24)
- Debug overlay via FLAPPY_DEBUG environment variable

## Modular architecture ✓

The codebase is split into seven focused modules:

- `main.asm` - Entry point, data definitions, main loop
- `terminal.asm` - Platform terminal management
- `input.asm` - Input polling and dispatch
- `gameplay.asm` - Shared state transitions and responsive layout rules
- `physics.asm` - Game logic and state machine
- `render.asm` - All drawing and presentation
- `util.asm` - Shared utilities (timing, strings, file I/O)

## Quality rules

## Rule 1: shared logic stays pure

Core gameplay files should not know about:

- Linux syscalls
- Windows handles
- console mode flags
- stdout encoding details

They should only operate on data structures.

## Rule 2: rendering stays deterministic

Given the same game state and terminal descriptor, rendering should produce the same cell buffer every time.

## Rule 3: platform code stays thin

Platform files should mostly:

- gather input
- report time
- manage terminal state
- handle file I/O
- enter the main loop

If platform files start containing game logic, the architecture is drifting.

## Rule 4: assembly remains readable

Prefer:

- named constants
- compact procedures
- predictable register use
- obvious stack discipline

Avoid:

- giant procedures
- hidden side effects
- stack tricks that save a few instructions but hurt clarity

## Rule 5: restore the terminal no matter what

This is a terminal game. A broken restore path ruins trust immediately.

Every exit path should restore:

- cursor visibility
- alternate screen state
- input mode changes
- any terminal title or style changes if used

## Performance guidance

Do not optimize before measurement. A full-frame ANSI write at the target grid size is likely good enough for version 1.

Premature complexity to avoid:

- dirty rectangle systems
- partial cursor-jump rendering
- overengineered object systems

If profiling later proves a bottleneck, optimize the encoder first.

## Main technical risks

### Risk 1: terminal variance

Different terminals render Unicode and color slightly differently.

Mitigation:

- build around strong defaults
- keep ASCII fallback
- prefer stable, standard ANSI sequences

### Risk 2: Windows input behavior

Output can be standardized with VT, but input is more platform-sensitive.

Mitigation:

- give Windows its own thin keyboard layer
- keep the shared gameplay loop independent of input source details

### Risk 3: over-designing the renderer

A terminal game can become harder than necessary if the renderer tries to be too smart too early.

Mitigation:

- start with a full-frame buffer
- write once per frame
- only add complexity after benchmarking

## Definition of success for the first playable build

The first genuinely successful milestone is not “bird moves.”

It is this:

- starts cleanly
- looks intentional
- feels responsive
- survives resize and quit paths
- leaves the terminal untouched afterward

Once that exists, the rest of the game can be added with confidence.
