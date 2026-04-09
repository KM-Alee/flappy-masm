param(
    [ValidateSet('release', 'debug')]
    [string]$Mode = 'release'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $root 'build/windows-native'
$sources = @(
    'src/main.asm',
    'src/physics.asm',
    'src/render.asm',
    'src/input_win.asm',
    'src/terminal_win.asm',
    'src/util_win.asm',
    'src/windows_crt.asm'
)

$uasm = Get-Command uasm -ErrorAction SilentlyContinue
$ml64 = Get-Command ml64 -ErrorAction SilentlyContinue
$gcc = Get-Command gcc -ErrorAction SilentlyContinue
$link = Get-Command link -ErrorAction SilentlyContinue

if (-not $uasm -and -not $ml64) {
    throw 'uasm or ml64 must be available in PATH.'
}

if (-not $gcc -and -not $link) {
    throw 'gcc or link.exe must be available in PATH.'
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
$objects = @()

foreach ($source in $sources) {
    $sourcePath = Join-Path $root $source
    $objectPath = Join-Path $buildDir (([IO.Path]::GetFileNameWithoutExtension($source)) + '.obj')
    if ($uasm) {
        & $uasm.Source -q -win64 -D TARGET_WINDOWS -Fo=$objectPath $sourcePath
    } else {
        & $ml64.Source /nologo /c /D TARGET_WINDOWS /Fo$objectPath $sourcePath
    }
    $objects += $objectPath
}

$target = Join-Path $buildDir 'flappy-term.exe'
if ($gcc) {
    $optimization = if ($Mode -eq 'debug') { '-g', '-O0' } else { '-O2' }
    & $gcc.Source @optimization '-Wl,--subsystem,console,--image-base,0x400000' '-o' $target $objects
} else {
    & $link.Source /NOLOGO /MACHINE:X64 /SUBSYSTEM:CONSOLE /BASE:0x400000 /OUT:$target $objects kernel32.lib msvcrt.lib
}

Write-Host "Built $target"