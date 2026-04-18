@echo off
set VERSION=V2460
set "GODOT_PATH=C:\Users\Terminal\Documents\Godot_4.3\Godot_v4.3-stable_win64.exe"

echo --- INICIANDO PIPELINE DE BUILD %VERSION% ---

echo [1/4] EXPORTANDO PROJETO GODOT (WEB)...
"%GODOT_PATH%" --headless --export-release "Web" "%~dp0index.html"
if %ERRORLEVEL% NEQ 0 (
    echo ERRO: Falha na exportacao do Godot
    pause
    exit /b %ERRORLEVEL%
)

echo [2/4] APLICANDO MASTER FIX (HTML PATCH)...
node patch_html.js
if %ERRORLEVEL% NEQ 0 (
    echo ERRO: Falha ao aplicar patch HTML
    pause
    exit /b %ERRORLEVEL%
)

echo [3/4] ADICIONANDO ARQUIVOS AO GIT...
git add .

echo [4/4] SUBINDO PARA O GITHUB...
git commit -m "feat: %VERSION% - CrazyGames Portal Template, 50%% Res Stabilization and Manual Resize Fix"
git push origin main --force

echo ------------------------------------------
echo FINALIZADO %VERSION% COM SUCESSO
echo ------------------------------------------
timeout /t 5
