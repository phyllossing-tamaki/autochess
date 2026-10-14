@echo off
rem Generic Godot CLI wrapper (auto-detect, console build). Usage: godot.bat <args>
call "%~dp0_godot_path.bat" || exit /b 1
"%GODOT_CONSOLE%" %*
