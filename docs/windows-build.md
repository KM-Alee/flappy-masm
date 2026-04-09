# Windows Build Guide

This repository now has a dedicated Windows build path that keeps the gameplay, physics, and renderer shared while swapping in Windows-specific console, timing, and input modules.

## What is supported

- Native Windows builds with `uasm` or `ml64`
- PowerShell build and run scripts
- Cross-building a Windows `.exe` from Linux with `uasm` and `x86_64-w64-mingw32-gcc`
- ANSI/VT output in Windows Terminal and modern conhost sessions

## Files added for Windows

- `Makefile.windows`
- `windows/build.ps1`
- `windows/run.ps1`
- `include/windows.inc`
- `src/input_win.asm`
- `src/terminal_win.asm`
- `src/util_win.asm`
- `src/windows_crt.asm`

## Native Windows prerequisites

You need one assembler in `PATH`:

- `uasm`
- or `ml64`

You also need one linker path:

- `gcc` from a MinGW-w64 environment
- or `link.exe` from Visual Studio Build Tools / Developer PowerShell

## Recommended native workflow

### Option 1: `uasm` + `gcc`

Open PowerShell in the repository root and run:

```powershell
./windows/build.ps1
./windows/run.ps1
```

Native script output is written to `build/windows-native/flappy-term.exe`.

### Option 2: `ml64` + `link.exe`

Open a Developer PowerShell for Visual Studio, make sure `ml64` is in `PATH`, then run:

```powershell
./windows/build.ps1
./windows/run.ps1
```

The build script detects the available toolchain automatically.
Native script output is written to `build/windows-native/flappy-term.exe`.

## GNU Make workflow

If you prefer `make` and have a Windows-compatible `make` installed:

```powershell
make -f Makefile.windows release
```

For a debug build:

```powershell
make -f Makefile.windows debug
```

Output is written to `build/windows/flappy-term.exe`.

## Linux cross-build to Windows

From Linux, build the Windows binary with:

```bash
make -f Makefile.windows release
```

That uses:

- `uasm -win64`
- `x86_64-w64-mingw32-gcc`

The resulting binary is:

`build/windows/flappy-term.exe`

## Development notes

- Shared gameplay stays in `src/physics.asm` and `src/render.asm`
- Windows input uses `_kbhit` and `_getch`
- Windows console sizing uses `GetConsoleScreenBufferInfo`
- ANSI output is enabled with `ENABLE_VIRTUAL_TERMINAL_PROCESSING`
- The Windows runtime re-checks console geometry each frame so resize behavior remains responsive without Linux signal handling

## Troubleshooting

If the build script says no linker is available:

- install MinGW-w64 and ensure `gcc` is in `PATH`
- or open a Visual Studio Developer PowerShell so `link.exe` is available

If the game launches but output looks wrong:

- run it in Windows Terminal or a modern PowerShell console
- avoid legacy console hosts without VT support

If audio does not play:

- ensure PowerShell is available
- ensure the `assets/*.wav` files exist next to the repository root