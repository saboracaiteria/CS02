@echo off
set VERSION=BUILD_ONLY
set GODOT_PATH=C:\Users\Terminal\Documents\Godot_4.3\Godot_v4.3-stable_win64.exe
echo [1/2] EXPORTANDO PROJETO GODOT (%VERSION%)...
"%GODOT_PATH%" --headless --export-release "Web" "C:\Users\Terminal\Documents\CS02\index.html"
echo [2/2] APLICANDO MASTER FIX...
node patch_html.js
echo FINALIZADO %VERSION% COM SUCESSO!
