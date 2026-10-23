<#
Installs MSYS2's UCRT64 CBC package and this local Raku distribution.
Run from an elevated PowerShell only when installing or updating MSYS2 itself.
#>
[CmdletBinding()]
param(
    [string] $MSYS2Root = 'C:\msys64'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$bash = Join-Path $MSYS2Root 'usr\bin\bash.exe'
$cbcBin = Join-Path $MSYS2Root 'ucrt64\bin'
$cbcDll = Join-Path $cbcBin 'libCbcSolver-3.dll'

if (-not (Test-Path $bash)) {
    throw "MSYS2 was not found at $MSYS2Root. Install it from https://www.msys2.org/, then rerun this script (or pass -MSYS2Root)."
}
if (-not (Get-Command zef -ErrorAction SilentlyContinue)) {
    throw 'zef is required. Install a Raku distribution with zef, then rerun this script.'
}

# CBC brings its Clp, CoinUtils, and other runtime dependencies with it.
& $bash -lc 'pacman -Syu --noconfirm; pacman -S --needed --noconfirm mingw-w64-ucrt-x86_64-coin-or-cbc'
if ($LASTEXITCODE -ne 0) { throw 'MSYS2 could not install the CBC package.' }
if (-not (Test-Path $cbcDll)) { throw "CBC DLL was not installed at $cbcDll." }

# NativeCall needs both the DLL and its dependent DLLs at runtime.
$env:PATH = "$cbcBin;$env:PATH"
$env:COIN_OR_CBC_LIBRARY = $cbcDll
[Environment]::SetEnvironmentVariable('COIN_OR_CBC_LIBRARY', $cbcDll, 'User')

& zef install $repoRoot
if ($LASTEXITCODE -ne 0) { throw 'zef could not install the local COIN-OR distribution.' }

Write-Host 'COIN-OR installed successfully. Open a new terminal before running Raku programs.'
