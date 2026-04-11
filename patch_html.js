const fs = require('fs');
const path = './index.html';

// VERSION AUTO-READER: Lê a versão direto do .bat para nunca ficar desatualizado! 🏙️🚀🥇
let VERSION = 'V2080'; // fallback
try {
    const batContent = fs.readFileSync('./AUTO_BUILD_PUSH.bat', 'utf8');
    const match = batContent.match(/set VERSION=([\w\d]+)/);
    if (match) VERSION = match[1];
} catch(e) {}


if (fs.existsSync(path)) {
    let content = fs.readFileSync(path, 'utf8');
    
    // INJETA ERUDA E DESBLOQUEIA ATALHOS NATIVOS 🔓🏙️
    const patch = `
		<style>
		@media screen and (orientation: portrait) {
		    #rotate-screen { display: flex !important; }
		    #canvas { display: none !important; }
		}
		#rotate-screen {
		    display: none;
		    position: fixed;
		    top: 0; left: 0; width: 100vw; height: 100vh;
		    background: #050505;
		    z-index: 9999999;
		    flex-direction: column;
		    align-items: center;
		    justify-content: center;
		    color: #ffd700;
		    font-family: Arial, sans-serif;
		    text-align: center;
		    padding: 20px;
		    box-sizing: border-box;
		}
		.rotate-icon {
		    width: 60px; height: 100px;
		    margin-bottom: 20px;
		    border: 4px solid #00f3ff;
		    border-radius: 10px;
		    animation: rotateAnim 2.5s infinite ease-in-out;
		}
		@keyframes rotateAnim {
		    0% { transform: rotate(0deg); }
		    50% { transform: rotate(90deg); }
		    100% { transform: rotate(90deg); }
		}
		</style>
		<div id="rotate-screen">
		    <div class="rotate-icon"></div>
		    <h1 style="font-size: 28px; text-transform: uppercase;">GIRE O CELULAR</h1>
		    <p style="color: #00f3ff; font-size: 16px;">Modo paisagem obrigatório para operar taticamente.</p>
		</div>
		<script src="https://cdn.jsdelivr.net/npm/eruda"></script>
		<script>eruda.init();</script>
		<script>
			// --- NATIVE UNLOCK ${VERSION} 🔓🏙️ ---
			(function() {
				const originalGetContext = HTMLCanvasElement.prototype.getContext;
				HTMLCanvasElement.prototype.getContext = function(type, attributes) {
					if (type === 'webgl' || type === 'webgl2') {
						attributes = attributes || {};
						attributes.preserveDrawingBuffer = true; // PERMITE PRINT E GRAVAÇÃO 📸
						attributes.alpha = true;
						attributes.antialias = true;
					}
					return originalGetContext.call(this, type, attributes);
				};
				
				// DESBLOQUEIA EVENTOS NATIVOS 🔓🏙️ (RESTAURADOS V2080)
				window.addEventListener('contextmenu', e => {}, true);
				window.addEventListener('touchstart', e => {}, {passive: true});
				// Keydown removido para não travar o Godot!
			})();
			
			function forceReload() {
				if ('serviceWorker' in navigator) {
					navigator.serviceWorker.getRegistrations().then(function(registrations) {
						for(let registration of registrations) { registration.unregister(); }
					});
				}
				if ('caches' in window) {
					caches.keys().then(function(names) {
						for (let name of names) caches.delete(name);
					});
				}
				localStorage.clear();
				sessionStorage.clear();
				window.location.href = window.location.origin + window.location.pathname + '?v=' + Date.now();
			}
		</script>
		<button id="reloadButton" onclick="forceReload()" style="position:fixed;top:15px;right:15px;z-index:9999;background:rgba(0,0,0,0.6);color:#ffd700;width:40px;height:40px;border-radius:50%;border:1px solid rgba(255,215,0,0.5);cursor:pointer;font-weight:bold;display:flex;align-items:center;justify-content:center;font-size:18px;backdrop-filter:blur(5px);box-shadow:0 4px 10px rgba(0,0,0,0.5);">🔄</button>
	`;
    
    // Remove patches antigos se existirem! 🛡️
    content = content.replace(/<button id="reloadButton"[\s\S]*?<\/button>/g, '');
    content = content.replace(/<script>[\s\S]*?MASTER KEY LOCK[\s\S]*?<\/script>/g, '');

    // Aplica o novo patch V1470!
    content = content.replace('</head>', patch + '</head>');
    fs.writeFileSync(path, content);
    console.log(`✅ HTML PATCHED: Versão ${VERSION} aplicada com sucesso!`);
}
