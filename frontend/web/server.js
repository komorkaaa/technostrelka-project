import http from "http";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const publicDir = path.join(__dirname, "public");
const port = process.env.PORT || 3000;
const backendBaseUrl = process.env.BACKEND_URL || "http://localhost:8000";

const routeMap = {
  "/": "/index.html",
  "/subscriptions": "/subscriptions.html",
  "/calendar": "/calendar.html",
  "/analytics": "/analytics.html",
  "/settings": "/settings.html",
  "/auth": "/auth.html"
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

function collectBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on("data", (chunk) => chunks.push(chunk));
    req.on("end", () => resolve(Buffer.concat(chunks)));
    req.on("error", reject);
  });
}

async function proxyApi(req, res) {
  const targetPath = req.url.replace(/^\/api/, "");
  const targetUrl = `${backendBaseUrl}${targetPath}`;
  const headers = {};

  if (req.headers["content-type"]) headers["content-type"] = req.headers["content-type"];
  if (req.headers["authorization"]) headers["authorization"] = req.headers["authorization"];

  let body;
  if (!["GET", "HEAD"].includes(req.method)) {
    body = await collectBody(req);
  }

  try {
    const apiResponse = await fetch(targetUrl, {
      method: req.method,
      headers,
      body
    });
    const contentType = apiResponse.headers.get("content-type") || "application/json; charset=utf-8";
    res.writeHead(apiResponse.status, { "Content-Type": contentType });
    const data = Buffer.from(await apiResponse.arrayBuffer());
    res.end(data);
  } catch (error) {
    send(res, 502, "application/json; charset=utf-8", JSON.stringify({ error: "Bad Gateway" }));
  }
}

const server = http.createServer(async (req, res) => {
  const rawPath = decodeURIComponent(req.url.split("?")[0]);
  let reqPath = rawPath;

  if (reqPath.startsWith("/api/")) {
    await proxyApi(req, res);
    return;
  }

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
