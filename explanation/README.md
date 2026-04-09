# Flappy ASM Explained

This folder is a guided tour of the codebase for readers who want to learn assembly by reading a complete game.

The goal is not only to say what each file does, but to explain why the project is structured this way and how the pieces cooperate frame by frame.

## Recommended reading order

1. `architecture.md`
2. `data-layout.md`
3. `game-loop-and-state.md`
4. `rendering-system.md`
5. `platform-and-io.md`
6. `build-and-debug.md`

## What you are looking at

This project is a terminal Flappy Bird clone written in x86-64 assembly with MASM-style syntax.

At a high level it works like this:

1. `main.asm` owns all shared data and runs the main loop.
2. The terminal layer sets up raw input and discovers the terminal size.
3. The input layer turns key presses into game actions.
4. The gameplay and physics layers update the bird, pipes, score, and state machine.
5. The render layer composes a full frame in memory.
6. The utility layer handles timing, formatting, persistence, and sound command dispatch.

## Why this codebase is a good study target

It is large enough to show real structure, but still small enough that you can read every file and understand the entire program.

Important educational themes in this repository:

- Shared global state with a single owning file.
- A fixed-timestep game loop.
- Pure logic separated from platform-specific terminal code.
- A full-frame renderer built on a cell buffer.
- Careful use of helper procedures to keep assembly readable.

## The most important idea

Almost every interesting system in this project follows the same pattern:

1. Read a small amount of outside state.
2. Translate it into a plain internal representation.
3. Update the internal representation deterministically.
4. Render from that representation.

That is why the code stays understandable. Each file has a narrow job, and most functions work on simple integers, arrays, and buffers instead of complicated hidden state.

## Study tips for assembly beginners

- Read one procedure at a time.
- Track register meaning in comments or notes as you go.
- Pay attention to where values live: registers, globals, arrays, or buffers.
- Learn the fixed-point format before reading the physics code.
- Learn the cell buffer before reading the ANSI encoder.

If you can explain the path from one key press to one rendered frame, you understand the whole project.