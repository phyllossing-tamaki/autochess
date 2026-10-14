@echo off
rem Headless asset import / validation (CI-safe, auto-detect).
call "%~dp0_godot_path.bat" || exit /b 1
pushd "%~dp0..\.."
"%GODOT_CONSOLE%" --headless --path . --import
popd
