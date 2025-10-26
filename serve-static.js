const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
const PUBLIC_DIR = path.join(__dirname, 'website'); // Directory to serve

const server = http.createServer((req, res) => {
    // Simple path routing: default to index.html
    let filePath = path.join(PUBLIC_DIR, req.url === '/' ? 'index.html' : req.url);

    // Ensure we don't allow directory traversal
    if (filePath.indexOf(PUBLIC_DIR) !== 0) {
        res.writeHead(403);
        res.end('403 Forbidden');
        return;
    }

    fs.readFile(filePath, (err, content) => {
        if (err) {
            if (err.code === 'ENOENT') {
                res.writeHead(404);
                res.end('404 Not Found');
            } else {
                res.writeHead(500);
                res.end('500 Internal Error: ' + err.code);
            }
        } else {
            // Set content type and serve the file
            const contentType = path.extname(filePath) === '.html' ? 'text/html' : 'text/plain';
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content, 'utf-8');
        }
    });
});

server.listen(PORT, () => {
    console.log(`Static server running at http://localhost:${PORT}/`);
});