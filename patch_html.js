const fs = require('fs');
const path = './index.html';

// VERSION AUTO-READER: Lê a versão direto do .bat para nunca ficar desatualizado! 🏙️🚀🥇
let VERSION = 'V1720'; // fallback
try {
    const batContent = fs.readFileSync('./AUTO_BUILD_PUSH.bat', 'utf8');
    const match = batContent.match(/set VERSION=(V\d+)/);
    if (match) VERSION = match[1];
} catch(e) {}


if (fs.existsSync(path)) {
    let content = fs.readFileSync(path, 'utf8');
    
    // INJETA ERUDA E TECLAS F5/F12 ✨🚀💎🥇
    const patch = `
		<script src="https://cdn.jsdelivr.net/npm/eruda"></script>
		<script>eruda.init();</script>
		<script>
			// --- MASTER KEY LOCK ${VERSION} ⛩️🚀 ---
			window.addEventListener('keydown', function(e) {
				// F12 e Refresh liberados para dev! 🎯
			}, true);
			
			function forceReload() {
				// Força limpeza total de cache
				if ('serviceWorker' in navigator) {
					navigator.serviceWorker.getRegistrations().then(function(registrations) {
						for(let registration of registrations) { registration.unregister(); }
					});
				}
				window.location.search = '?v=' + Date.now();
				window.location.reload(true);
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
