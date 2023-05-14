// // fetch the current date and time
// let now = new Date();
// let month = now.getMonth() + 1;

// console.log(month);

// // read JSON file
// let myData;

// fetch('http://localhost/db/Jun-2023.processed.json')
//     .then(response => response.json())
//     .then(parsed_data => {
//         // Assign the parsed data to the variable
//         myData = parsed_data;
//         console.log(myData); // This should log the parsed data
//     })
//     .catch(error => {
//         // Handle any errors that occur
//         console.error(error);
//     });

const http = require('http');
const fs = require('fs');
const path = require('path');

const port = 8000;

const server = http.createServer((request, response) => {
    console.log(`${request.method} ${request.url}`);

    let filePath = '.' + request.url;
    if (filePath == './') {
        filePath = './index.html';
    }

    const extname = String(path.extname(filePath)).toLowerCase();
    const mimeTypes = {
        '.html': 'text/html',
        '.js': 'text/javascript',
        '.css': 'text/css',
        '.json': 'application/json',
        '.png': 'image/png',
        '.jpg': 'image/jpg',
        '.gif': 'image/gif',
        '.svg': 'image/svg+xml',
        '.wav': 'audio/wav',
        '.mp4': 'video/mp4',
        '.woff': 'application/font-woff',
        '.ttf': 'application/font-ttf',
        '.eot': 'application/vnd.ms-fontobject',
        '.otf': 'application/font-otf',
        '.wasm': 'application/wasm',
    };

    const contentType = mimeTypes[extname] || 'application/octet-stream';

    fs.readFile(filePath, (error, content) => {
        if (error) {
            if (error.code == 'ENOENT') {
                response.writeHead(404, { 'Content-Type': 'text/html' });
                response.end('<h1>404 Not Found</h1>');
            } else {
                response.writeHead(500, { 'Content-Type': 'text/html' });
                response.end(`<h1>500 Internal Server Error</h1><p>${error}</p>`);
            }
        } else {
            response.writeHead(200, { 'Content-Type': contentType });
            response.end(content, 'utf-8');
        }
    });
});

server.listen(port, () => {
    console.log(`Server running at http://localhost:${port}/`);
});
