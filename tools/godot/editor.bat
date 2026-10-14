@echo off
rem Open this project in the Godot editor (auto-detect Godot executable).
call "%~dp0_godot_path.bat" || exit /b 1
pushd "%~dp0..\.."
"%GODOT_GUI%" --path . --editor
popd
