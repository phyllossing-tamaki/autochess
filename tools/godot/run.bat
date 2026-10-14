@echo off
rem Run the project (main scene, auto-detect).
call "%~dp0_godot_path.bat" || exit /b 1
pushd "%~dp0..\.."
"%GODOT_GUI%" --path .
popd
