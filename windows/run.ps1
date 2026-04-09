param(
    [ValidateSet('release', 'debug')]
    [string]$Mode = 'release'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
& (Join-Path $PSScriptRoot 'build.ps1') -Mode $Mode
& (Join-Path $root 'build/windows-native/flappy-term.exe')