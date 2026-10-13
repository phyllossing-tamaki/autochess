@echo off
rem Open this project in the Godot editor.
pushd "%~dp0..\.."
"%~dp0Godot_v4.5.1-stable_win64.exe" --path . --editor
popd
