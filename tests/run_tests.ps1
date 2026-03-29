param(
	[string]$GodotPath = "godot4"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
try {
	& $GodotPath --headless --path $projectRoot --script res://tests/run_tests.gd
	exit $LASTEXITCODE
} catch {
	Write-Error "Unable to launch Godot from '$GodotPath'. Pass -GodotPath with your Godot 4.6 executable path or add it to PATH."
	exit 1
}
