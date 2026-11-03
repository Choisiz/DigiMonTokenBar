param([switch]$CheckOnly, [string]$BuildDirectory = '')
$ErrorActionPreference = 'Stop'
if (-not $env:CARGO_BUILD_JOBS) { $env:CARGO_BUILD_JOBS = '1' }
$projectDirectory = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectDirectory
if (-not $BuildDirectory) { $BuildDirectory = Join-Path $projectDirectory '../.build-windows' }
$resolvedBuildDirectory = [IO.Path]::GetFullPath($BuildDirectory)
New-Item -ItemType Directory -Path $resolvedBuildDirectory -Force -ErrorAction Stop | Out-Null
$temporaryDirectory = Join-Path $resolvedBuildDirectory 'temp'
New-Item -ItemType Directory -Path $temporaryDirectory -Force -ErrorAction Stop | Out-Null
$env:CARGO_TARGET_DIR = Join-Path $resolvedBuildDirectory 'target'
$env:TEMP = $temporaryDirectory
$env:TMP = $temporaryDirectory
Write-Host "Build files: $env:CARGO_TARGET_DIR"
$vswherePath = Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'Microsoft Visual Studio/Installer/vswhere.exe'
if (-not (Test-Path -LiteralPath $vswherePath)) { throw 'Install Visual Studio Build Tools: Desktop development with C++ (MSVC and Windows SDK).' }
$visualStudioPath = & $vswherePath -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $visualStudioPath) { throw 'MSVC is missing. Select Desktop development with C++ in Visual Studio Installer.' }
if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
 $localToolchain = Join-Path $projectDirectory '../.local-tools'
 if (-not (Test-Path -LiteralPath $localToolchain)) { $localToolchain = Join-Path $projectDirectory '../../../work/toolchain' }
 $localRust = Join-Path $localToolchain 'rustup/toolchains/stable-x86_64-pc-windows-msvc/bin'
 if (-not (Test-Path -LiteralPath (Join-Path $localRust 'cargo.exe'))) { throw 'Install Rust MSVC stable and reopen PowerShell.' }
 $env:CARGO_HOME = (Resolve-Path -LiteralPath (Join-Path $localToolchain 'cargo')).Path
 $env:RUSTUP_HOME = (Resolve-Path -LiteralPath (Join-Path $localToolchain 'rustup')).Path
 $env:PATH = "$localRust;$env:PATH"
}
& npm.cmd test
if ($LASTEXITCODE -ne 0) { throw 'Frontend tests failed.' }
& npm.cmd run build
if ($LASTEXITCODE -ne 0) { throw 'Frontend build failed.' }
& cargo.exe test --release --manifest-path src-tauri/Cargo.toml
if ($LASTEXITCODE -ne 0) { throw 'Native tests failed.' }
if (-not $CheckOnly) {
 & npm.cmd run build:windows
 if ($LASTEXITCODE -ne 0) { throw 'Windows build failed.' }
 Write-Host "Built: $env:CARGO_TARGET_DIR/release/digimon-tokenbar.exe"
}
