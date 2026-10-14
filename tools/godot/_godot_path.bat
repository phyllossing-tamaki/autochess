@echo off
rem Resolve Godot executables: sets GODOT_GUI and GODOT_CONSOLE.
rem 1) Prefer a portable build in this folder (Godot*_console.exe / Godot*.exe).
rem 2) Fall back to godot / godot_console on PATH.
set "GODOT_GUI="
set "GODOT_CONSOLE="
for /f "delims=" %%F in ('dir /b /a-d "%~dp0Godot*_console.exe" 2^>nul') do set "GODOT_CONSOLE=%~dp0%%F"
for /f "delims=" %%F in ('dir /b /a-d "%~dp0Godot*.exe" 2^>nul ^| findstr /i /v "_console"') do set "GODOT_GUI=%~dp0%%F"
if not defined GODOT_GUI for /f "delims=" %%P in ('where godot.exe 2^>nul') do set "GODOT_GUI=%%P"
if not defined GODOT_CONSOLE for /f "delims=" %%P in ('where godot_console.exe 2^>nul') do set "GODOT_CONSOLE=%%P"
if not defined GODOT_CONSOLE for /f "delims=" %%P in ('where godot.exe 2^>nul') do set "GODOT_CONSOLE=%%P"
if not defined GODOT_GUI set "GODOT_GUI=%GODOT_CONSOLE%"
if not defined GODOT_CONSOLE set "GODOT_CONSOLE=%GODOT_GUI%"
if not defined GODOT_GUI (echo [godot] No Godot executable found. Put a portable build in "%~dp0" or add godot.exe to PATH. & exit /b 1)
exit /b 0
