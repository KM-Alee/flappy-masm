# Game Loop And State Machine

## The loop in one sentence

The main loop repeatedly:

1. refreshes terminal geometry if needed
2. polls input
3. advances simulation in fixed steps
4. renders one frame
5. sleeps for the remaining frame budget

That is the full game.

## Where the loop lives

The loop is in `main.asm`, inside `main`.

This procedure performs startup, then drops into a `main_loop` label that repeats until `exit_requested` becomes non-zero.

## Startup sequence

Before the loop begins, `main` does this work:

1. detect debug mode
2. seed the RNG
3. load the best score
4. set up the terminal
5. install process hooks
6. read initial geometry
7. reset the run
8. capture the initial clock value

That means the game reaches the first frame already knowing:

- the terminal size
- the initial bird position
- the current best score
- whether the terminal is valid

## Fixed timestep

The simulation uses a fixed tick size of `FRAME_NS`, which is approximately 16.67 ms, or 60 updates per second.

This is important because it separates gameplay correctness from render timing.

The program does not say “move based on however long the last frame took.” Instead, it says “accumulate real time, then spend it in exact simulation-sized chunks.”

Benefits:

- stable physics
- consistent feel across fast and slow machines
- easier reasoning about gravity and pipe speed

## Accumulator model

`main.asm` keeps an `accumulator_ns` value.

Each outer-loop iteration:

1. reads the current clock
2. computes elapsed nanoseconds since the previous frame
3. clamps extreme deltas
4. adds the delta to `accumulator_ns`
5. runs `UpdateGame` while the accumulator still holds at least one full tick

The loop also caps the number of updates per frame to 5 so the program cannot spiral into a massive catch-up loop.

That is a standard and correct fixed-timestep game technique.

## Game states

The state machine is intentionally small:

- `STATE_TITLE`
- `STATE_RUNNING`
- `STATE_PAUSED`
- `STATE_DEAD`

Each state changes what input means and what simulation work happens.

## Input meaning by state

Shared helpers in `gameplay.asm` centralize the action rules.

### Flap key

- on title: start the run
- on dead: reset and restart
- on running: apply upward velocity
- on paused: do nothing

### Pause key

- on running: enter paused
- on paused: resume running
- on other states: do nothing

### Restart key

- on dead: reset and restart
- otherwise: do nothing

This is exactly the kind of logic that is easy to duplicate incorrectly across platforms, which is why extracting it into one module was a good simplification.

## What `ResetRun` does

`ResetRun` in `physics.asm` prepares a fresh session.

It:

- sets the state to title
- clears the score
- clears bird velocity
- vertically centers the bird
- places the pipe set off-screen to the right
- gives each pipe a random gap row
- resets scoring flags for the pipes

This is the procedure that says “build a valid starting world.”

## What `StartRun` does

`StartRun` transitions from a waiting state into active play.

It:

- checks `small_terminal`
- sets the state to running
- gives the bird the initial flap velocity

That first upward impulse is why the bird feels responsive the moment play starts.

## What `UpdateGame` does

`UpdateGame` is the simulation tick.

It behaves differently by state.

### Running state

In `STATE_RUNNING`, the function:

1. adds gravity to bird velocity
2. clamps fall speed
3. updates bird position
4. scrolls every pipe leftward
5. awards score when a pipe is passed
6. recycles pipes that move off-screen
7. checks floor, ceiling, and pipe collisions
8. kills the run if a collision occurs

### Dead state

In `STATE_DEAD`, the bird keeps falling until it reaches the ground.

This is a small but important polish detail. The crash feels like a continuation of motion instead of an immediate freeze.

## Collision model

Collision happens in two steps:

1. vertical bounds check against ceiling and ground
2. horizontal overlap with each pipe, followed by a gap test

The model is intentionally simple because the game is based on a coarse terminal grid.

That simplicity is a strength. There is no need for complicated geometry here.

## Scoring model

Each pipe pair can only score once.

The program checks whether the bird has moved past the pipe's right edge. If so, and if `pipes_scored[i]` is still zero, it:

- marks the pipe as scored
- increments `score_value`
- plays the point sound

This is a clean design because scoring is tied to pipe lifecycle instead of to a separate event queue.

## Best score updates

When the run dies, `KillRun` compares `score_value` with `best_score`.

If the new score is larger, it writes the new best score to disk immediately.

That means persistence happens at the natural moment of finality: the run ending.