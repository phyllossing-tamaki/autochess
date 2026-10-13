@echo off
rem Run the project (main scene).
pushd "%~dp0..\.."
"%~dp0Godot_v4.5.1-stable_win64.exe" --path .
popd
