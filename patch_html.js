const fs = require('fs');
const path = './index.html';

// VERSION AUTO-READER 🏙️🚀🥇
let VERSION = 'V2460';
try {
    const batContent = fs.readFileSync('./AUTO_BUILD_PUSH.bat', 'utf8');
    const match = batContent.match(/set VERSION=([\w\d]+)/);
    if (match) VERSION = match[1];
} catch(e) {}

if (fs.existsSync(path)) {
    let content = fs.readFileSync(path, 'utf8');
    
    // 1. EXTRAIR CONFIGURAÇÃO DO GODOT E FORÇAR RESIZE POLICY 0 (MANUAL) 🛠️
    const configMatch = content.match(/const GODOT_CONFIG = (\{.*?\});/);
    let godotConfig = configMatch ? configMatch[1] : '{"args":[],"canvasResizePolicy":0}';
    
    // Força canvasResizePolicy para 0 (Nós controlaremos o tamanho via JS)
    godotConfig = godotConfig.replace(/"canvasResizePolicy":\d/, '"canvasResizePolicy":0');

    // 2. TEMPLATE MASTER DA CRAZY GAMES (ALTA PERFORMANCE) 🏙️🎯🥇
    const masterTemplate = `<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>CRAZY GAMES PORTAL - FIELD OPS</title>
    <style>
        :root {
            --bg-color: #050505;
            --panel-bg: #111111;
            --accent-yellow: #f8ef02;
            --text-main: #ffffff;
            --text-dim: #888888;
            --border-color: #222222;
        }

        body {
            margin: 0;
            padding: 0;
            background-color: var(--bg-color);
            color: var(--text-main);
            font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            overflow-x: hidden;
            display: flex;
            flex-direction: column;
            align-items: center;
        }

        header {
            width: 100%;
            padding: 15px 20px;
            background: #000;
            border-bottom: 2px solid #00ff00;
            display: flex;
            align-items: center;
            box-sizing: border-box;
        }

        .logo { font-weight: 900; font-size: 20px; letter-spacing: 1px; }
        .logo span { color: var(--accent-yellow); }

        .main-wrapper {
            width: 100%;
            max-width: 1000px;
            margin-top: 20px;
            display: flex;
            flex-direction: column;
            gap: 15px;
            padding: 0 10px;
            box-sizing: border-box;
        }

        .game-frame {
            position: relative;
            background: #000;
            width: 100%;
            aspect-ratio: 16 / 9;
            box-shadow: 0 10px 30px rgba(0,0,0,0.5);
            border: 1px solid var(--border-color);
            overflow: hidden;
        }

        #canvas { width: 100%; height: 100%; display: block; image-rendering: pixelated; image-rendering: crisp-edges; }
        #canvas:focus { outline: none; }

        .info-bar {
            background: var(--panel-bg);
            padding: 15px 20px;
            border-radius: 4px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border: 1px solid var(--border-color);
        }

        .game-title { font-weight: bold; text-transform: uppercase; font-size: 18px; }

        .btn-fullscreen {
            background: #000;
            border: 2px solid #fff;
            color: #fff;
            padding: 8px 15px;
            font-size: 11px;
            font-weight: bold;
            cursor: pointer;
            transition: 0.2s;
        }
        .btn-fullscreen:hover { background: #fff; color: #000; }

        .about-section {
            background: var(--panel-bg);
            padding: 25px;
            border-radius: 4px;
            border: 1px solid var(--border-color);
        }
        .about-section h2 { margin: 0 0 10px 0; font-size: 22px; }
        .about-section p { color: var(--text-dim); line-height: 1.6; font-size: 14px; }

        .status-footer {
            width: 100%;
            margin-top: 15px;
            background: var(--accent-yellow);
            color: #000;
            padding: 8px;
            text-align: center;
            font-weight: 800;
            font-size: 12px;
            text-transform: uppercase;
        }

        #status {
            position: absolute;
            top: 0; left: 0; width: 100%; height: 100%;
            background: #111;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            z-index: 10;
        }

        #status-progress { width: 60%; height: 4px; appearance: none; margin-top: 20px; }
        #status-progress::-webkit-progress-bar { background: #222; }
        #status-progress::-webkit-progress-value { background: var(--accent-yellow); }

        #rotate-screen {
            display: none;
            position: fixed;
            top: 0; left: 0; width: 100vw; height: 100vh;
            background: #000;
            z-index: 99999;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            text-align: center;
        }
        @media (orientation: portrait) { #rotate-screen { display: flex; } }

        /* MODO MOBILE (SEM TEMPLATE) 📱 */
        body.is-mobile header,
        body.is-mobile .info-bar,
        body.is-mobile .about-section,
        body.is-mobile footer,
        body.is-mobile .status-footer {
            display: none !important;
        }

        body.is-mobile .main-wrapper {
            margin: 0;
            padding: 0;
            max-width: 100vw;
            height: 100vh;
        }

        body.is-mobile .game-frame {
            width: 100vw;
            height: 100vh;
            aspect-ratio: auto;
            border: none;
        }
    </style>
</head>
<body>
    <header><div class="logo">CRAZY GAMES <span>PORTAL</span></div></header>
    <div class="main-wrapper">
        <div class="game-frame" id="game-container">
            <canvas id="canvas">Browser not supported.</canvas>
            <div id="status">
                <img src="index.png?v=V2460" alt="Logo" style="max-width: 150px; margin-bottom: 20px;">
                <div style="font-weight: bold; letter-spacing: 2px; font-size: 14px;">INICIALIZANDO OPERAÇÃO...</div>
                <progress id="status-progress"></progress>
                <div id="status-notice" style="margin-top: 10px; color: var(--text-dim); font-size: 11px;"></div>
            </div>
        </div>
        <div class="info-bar">
            <div class="game-title">FIELD OPS: CS-MULTIPLAYER</div>
            <button class="btn-fullscreen" onclick="toggleFullscreen()">TELA CHEIA</button>
        </div>
        <div class="about-section">
            <h2>SOBRE O JOGO</h2>
            <p>Ação tática pura com cores sólidas e vibrantes. Desenvolvido para máxima performance em hardware limitado.</p>
        </div>
        <div class="status-footer">BATALHA INICIA EM BREVE - SERVIDOR ATIVO</div>
    </div>
    <div id="rotate-screen"><h1 style="color: var(--accent-yellow);">GIRE O CELULAR</h1></div>

    <script src="index.js?v=V2460"></script>
    <script>
        const GODOT_CONFIG = CUSTOM_CONFIG;
        const engine = new Engine(GODOT_CONFIG);

        // DETECÇÃO DE MOBILE 📱
        const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
        if (isMobile) {
            document.body.classList.add('is-mobile');
        }

        function toggleFullscreen() {
            const container = document.getElementById('game-container');
            if (!document.fullscreenElement) { container.requestFullscreen(); }
            else { document.exitFullscreen(); }
        }

        // --- SISTEMA DE FULLSCREEN NATIVO (MOBILE GESTURE) 🚀 ---
        window.requestNativeFullscreen = function() {
            const container = document.getElementById('game-container');
            if (isMobile && !document.fullscreenElement) {
                container.requestFullscreen().catch(err => {
                    console.log("Fullscreen blocked or failed:", err);
                });
            }
        };

        // --- MANIPULAÇÃO DE TAMANHO (RESIZE) ---
        function adjustCanvasSize() {
            const canvas = document.getElementById('canvas');
            const container = document.getElementById('game-container');
            if (canvas && container) {
                const rect = container.getBoundingClientRect();
                const dpr = window.devicePixelRatio || 1;
                canvas.width = rect.width * dpr;
                canvas.height = rect.height * dpr;
                // Comunica ao motor o novo tamanho se ele j\u00e1 estiver rodando
                if (typeof engine !== 'undefined' && engine.updateSize) {
                    engine.updateSize();
                }
            }
        }
        window.addEventListener('resize', adjustCanvasSize);

        (function () {
            const statusOverlay = document.getElementById('status');
            const statusProgress = document.getElementById('status-progress');
            const statusNotice = document.getElementById('status-notice');
            engine.startGame({
                'onProgress': (current, total) => {
                    if (total > 0) {
                        statusProgress.value = current;
                        statusProgress.max = total;
                    }
                },
            }).then(() => { 
                statusOverlay.style.display = 'none'; 
                adjustCanvasSize();
                setTimeout(adjustCanvasSize, 100);
            });
        }());
    </script>
</body>
</html>`;

    // APLICA CONFIGURAÇÃO REAL 🛠️
    let finalContent = masterTemplate.replace('CUSTOM_CONFIG', godotConfig);
    
    fs.writeFileSync(path, finalContent);
    console.log(`✅ MASTER PATCHED: Template CrazyGames ${VERSION} aplicado!`);
}
