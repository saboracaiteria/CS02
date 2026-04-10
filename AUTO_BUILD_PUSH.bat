@echo off
set VERSION=V2000
set GODOT_PATH=C:\Users\Terminal\Documents\Godot_4.3\Godot_v4.3-stable_win64.exe
echo [1/4] EXPORTANDO PROJETO GODOT (%VERSION%)...
"%GODOT_PATH%" --headless --export-release "Web" "C:\Users\Terminal\Documents\CS02\index.html"
echo [2/4] APLICANDO MASTER FIX...
node patch_html.js
echo [4/4] SUBINDO PARA O GITHUB...
git add .
git commit -m "fix: %VERSION% - HOST button and script redundancy"
echo [4/4] SUBINDO PARA O GITHUB...
git push origin main --force
echo FINALIZADO %VERSION% COM SUCESSO!
timeout /t 5
