@echo off
rem Run the layered battle map test scene (G grid / B background / T tiles / U units).
call "%~dp0_godot_path.bat" || exit /b 1
pushd "%~dp0..\.."
"%GODOT_GUI%" --path . scenes/dev/map_layer_test.tscn
popd
