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
		<button id="reloadButton" onclick="forceReload()" style="position:fixed;top:10px;left:50%;transform:translateX(-50%);z-index:9999;background:linear-gradient(90deg, #ff0000, #ff5500);color:white;padding:12px 25px;border-radius:25px;border:2px solid white;cursor:pointer;font-weight:bold;box-shadow:0 0 30px rgba(255,0,0,0.7);font-family:sans-serif;">🔥 FORCE RELOAD ${VERSION} ✨🎯</button>
	`;
    
    // Remove patches antigos se existirem! 🛡️
    content = content.replace(/<button id="reloadButton"[\s\S]*?<\/button>/g, '');
    content = content.replace(/<script>[\s\S]*?MASTER KEY LOCK[\s\S]*?<\/script>/g, '');

    // Aplica o novo patch V1470!
    content = content.replace('</head>', patch + '</head>');
    fs.writeFileSync(path, content);
    console.log(`✅ HTML PATCHED: Versão ${VERSION} aplicada com sucesso!`);
}
