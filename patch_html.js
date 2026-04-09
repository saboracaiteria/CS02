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
    
    // REMOVE ERUDA (DEBUG BUBBLE) V1760 🚫🔮
    content = content.replace(/<script src=".*eruda.*"><\/script>/g, '');
    content = content.replace(/<script>eruda.init\(\);<\/script>/g, '');

    
    // Injeta o Reload e Teclas F5/F12 ✨🚀💎🥇
    const patch = `
		<script>
			// --- MASTER KEY LOCK ${VERSION} ⛩️🚀 ---
			window.addEventListener('keydown', function(e) {
				if (e.key === 'F5' || e.key === 'F12' || (e.ctrlKey && e.key === 'r') || (e.ctrlKey && e.shiftKey && e.key === 'R')) {
					// Libera o F5 apenas se o usuário realmente quiser recarregar tudo!
				}
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
