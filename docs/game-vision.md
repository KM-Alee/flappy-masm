# Game Vision

## Core experience

This project should feel like the cleanest possible assembly Flappy Bird:

- one-button gameplay
- immediate response
- readable playfield
- satisfying failure state
- strong replay rhythm

The player should feel that every death was understandable and every success was earned.

## Gameplay rules

The game remains intentionally close to classic Flappy Bird:

- the bird has a fixed horizontal position
- gravity constantly pulls the bird downward
- flap applies an immediate upward impulse
- pipes move from right to left
- score increases when the bird fully passes a pipe pair
- collision with a pipe, floor, or ceiling ends the run

## Control philosophy

The game should feel excellent on both Linux terminals and Windows console hosts.

### Default controls

- `Space`: flap
- `W`: flap
- `Up Arrow`: flap
- `P`: pause/unpause
- `R`: restart after crash
- `Q` or `Esc`: quit

### Control quality rules

- never wait for Enter
- use non-blocking input
- process multiple key sources as equivalent flap actions
- consume input every frame
- favor responsiveness over realism

### Feel improvements to plan for

These are small changes that improve feel without changing the identity of the game:

- input buffering for a very short flap window
- consistent fixed-timestep simulation
- slightly forgiving hitbox relative to the visible bird
- optional pause that fully freezes simulation

## Visual direction

The renderer should aim for **clean, premium terminal art**, not noisy novelty.

### Scene composition

- smooth blue sky gradient (deep blue top, lighter toward ground)
- drifting white block clouds
- solid green pipes with lighter cap accents
- solid color-block ground (green grass strip + brown earth)
- bright yellow multi-cell bird sprite that always stands out
- centered score at the top with contrasting background
- best score at top-right during gameplay
- restrained overlays for start, pause, and game over states

### Current glyph strategy

The bird uses a multi-cell ASCII sprite:

```
__()>
 \_)
```

- Bird body: yellow (226), beak: orange (208), dead: red (196)
- Pipes: solid color blocks (dark green 28 body, lighter green 34 caps)
- Ground: solid color blocks (green 34 grass, brown 130 earth)
- Clouds: white space blocks (255)
- Sky: solid blue gradient (17, 18, 19, 25, 26, 32, 33, 39)

## Recommended playfield sizing

The game should adapt to the current terminal, but it needs sensible limits.

### Minimum supported size

- `80 x 24`

Below this, the program should show a centered warning and refuse to start gameplay.

### Recommended size

- `100 x 30`
- `120 x 40`

These sizes give enough room for strong visual spacing and smoother obstacle readability.

## States and overlays

The game should have only a few states:

- boot
- title / waiting to start
- active play
- paused
- crashed / game over

Each state should have a distinct overlay treatment, but the same underlying renderer.

### Start screen

- title
- short control hints
- quiet animated background
- invitation to press `Space`

### Pause screen

- dimmed playfield or a compact centered label
- no simulation updates

### Game over screen

- strong but not messy emphasis
- current score
- high score
- restart hint

## Scope choices for version 1

Include:

- one bird skin
- one pipe theme
- one day palette
- optional tiny particle burst on score and death

Defer:

- multiple themes
- sound effects beyond maybe a simple terminal bell experiment
- elaborate menus
- config files beyond what is necessary

That scope keeps the first implementation focused on quality.
