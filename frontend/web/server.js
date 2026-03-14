import http from "http";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const publicDir = path.join(__dirname, "public");
const port = process.env.PORT || 3000;

const routeMap = {
  "/subscriptions": "/subscriptions.html",
  "/calendar": "/calendar.html",
  "/analytics": "/analytics.html",
  "/settings": "/settings.html"
};

const mimeTypes = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".ico": "image/x-icon",
  ".json": "application/json; charset=utf-8"
};

function send(res, statusCode, contentType, body) {
  res.writeHead(statusCode, { "Content-Type": contentType });
  res.end(body);
}

function serveFile(filePath, res) {
  fs.readFile(filePath, (err, data) => {
    if (err) {
      send(res, 404, "text/plain; charset=utf-8", "Not Found");
      return;
    }
    const ext = path.extname(filePath).toLowerCase();
    const contentType = mimeTypes[ext] || "application/octet-stream";
    send(res, 200, contentType, data);
  });
}

const server = http.createServer((req, res) => {
  const rawPath = decodeURIComponent(req.url.split("?")[0]);
  let reqPath = rawPath === "/" ? "/index.html" : rawPath;

  if (routeMap[reqPath]) {
    reqPath = routeMap[reqPath];
  }

  if (reqPath.endsWith("/")) {
    reqPath += "index.html";
  }

  const safePath = path.normalize(reqPath).replace(/^([..\\/])+/, "");
  const filePath = path.join(publicDir, safePath);

  if (!filePath.startsWith(publicDir)) {
    send(res, 403, "text/plain; charset=utf-8", "Forbidden");
    return;
  }

  fs.stat(filePath, (err, stat) => {
    if (err || !stat.isFile()) {
      send(res, 404, "text/plain; charset=utf-8", "Not Found");
      return;
    }
    serveFile(filePath, res);
  });
});

server.listen(port, () => {
  console.log(`SubMonitor running at http://localhost:${port}`);
});
