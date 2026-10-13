@echo off
rem Headless asset import / validation (CI-safe).
pushd "%~dp0..\.."
"%~dp0Godot_v4.5.1-stable_win64_console.exe" --headless --path . --import
popd
