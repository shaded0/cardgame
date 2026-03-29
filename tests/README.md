# Testing

Run the suite headlessly with Godot 4.6:

```powershell
godot4 --headless --path . --script res://tests/run_tests.gd
```

If Godot is not on your `PATH`, point the helper script at the executable:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run_tests.ps1 -GodotPath "C:\path\to\Godot_v4.6-stable_win64.exe"
```
