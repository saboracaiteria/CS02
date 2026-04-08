const fs = require('fs');
const path = require('path');

function walk(dir, done) {
    let results = [];
    fs.readdir(dir, function(err, list) {
        if (err) return done(err);
        let i = 0;
        (function next() {
            let file = list[i++];
            if (!file) return done(null, results);
            file = path.resolve(dir, file);
            fs.stat(file, function(err, stat) {
                if (stat && stat.isDirectory()) {
                    if (file.includes('.godot') || file.includes('.git')) {
                        next();
                    } else {
                        walk(file, function(err, res) {
                            results = results.concat(res);
                            next();
                        });
                    }
                } else {
                    if (file.endsWith('.import')) {
                        results.push(file);
                    }
                    next();
                }
            });
        })();
    });
}

walk('.', function(err, results) {
    if (err) throw err;
    let modified = 0;
    results.forEach(file => {
        let content = fs.readFileSync(file, 'utf8');
        if (content.includes('importer="texture"')) {
            let newContent = content.replace(/process\/size_limit=\d+/g, 'process/size_limit=1024');
            // Try to force lossy or VRAM to significantly reduce PCK
            newContent = newContent.replace(/compress\/mode=0/g, 'compress/mode=1'); 
            if (content !== newContent) {
                fs.writeFileSync(file, newContent);
                modified++;
            }
        }
    });
    console.log(`Optimized ${modified} texture imports.`);
});
