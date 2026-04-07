const fs = require('fs');
const path = './index.html';

if (fs.existsSync(path)) {
    let content = fs.readFileSync(path, 'utf8');
    
    // Injeta o Reload e Teclas F5/F12 (V1380) ⛩️🚀💎🥇
    const patch = `
		<script>
			// --- MASTER KEY LOCK V1380 ⛩️🚀 ---
			window.addEventListener('keydown', function(e) {
				if (e.key === 'F5' || e.key === 'F12' || (e.ctrlKey && e.key === 'r') || (e.ctrlKey && e.shiftKey && e.key === 'R')) {
					e.stopPropagation();
				}
			}, true);
			
			function forceReload() {
				window.location.reload(true);
			}
		</script>
		<button id="reloadButton" onclick="forceReload()" style="position:fixed;top:10px;left:50%;transform:translateX(-50%);z-index:9999;background:red;color:white;padding:10px 20px;border-radius:20px;border:none;cursor:pointer;font-weight:bold;box-shadow:0 0 20px rgba(255,0,0,0.5)">🔄 FORCE RELOAD V1380 🏙️🎯</button>
	`;
    
    if (!content.includes('MASTER KEY LOCK V1380')) {
        content = content.replace('</head>', patch + '</head>');
        fs.writeFileSync(path, content);
        console.log('✅ HTML PATCHED: Teclas e Botão restaurados (V1380)!');
    } else {
        console.log('✨ HTML já está com o Patch V1380.');
    }
}
