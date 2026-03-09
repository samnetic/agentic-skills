#!/usr/bin/env node
/**
 * Excalidraw live editor backend.
 *
 * Serves the .excalidraw file via API and watches for changes.
 * Accepts saves from the browser and writes back to disk.
 * Designed to run alongside the Vite dev server (preview-app).
 *
 * Usage:
 *   node preview_server.mjs <file.excalidraw> [--port 8092] [--open]
 *
 * The Vite dev server runs on 8091 and proxies /api/* to this server on 8092.
 * Use --open to auto-launch the browser pointed at the Vite server.
 */

import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { exec } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Parse args
const args = process.argv.slice(2);
let filePath = null;
let port = 8092;
let autoOpen = false;
let vitePort = 8091;

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--port' && args[i + 1]) { port = parseInt(args[++i]); }
  else if (args[i] === '--vite-port' && args[i + 1]) { vitePort = parseInt(args[++i]); }
  else if (args[i] === '--open') { autoOpen = true; }
  else if (!args[i].startsWith('-')) { filePath = args[i]; }
}

if (!filePath) {
  console.error('Usage: node preview_server.mjs <file.excalidraw> [--port 8092] [--open]');
  process.exit(1);
}

filePath = path.resolve(filePath);

if (!fs.existsSync(filePath)) {
  console.error(`File not found: ${filePath}`);
  process.exit(1);
}

// File watching — track version for polling
let fileVersion = 0;
let lastMtime = fs.statSync(filePath).mtimeMs;
let suppressWatchUntil = 0;  // Suppress watch events right after we write

fs.watch(filePath, () => {
  if (Date.now() < suppressWatchUntil) return;
  try {
    const newMtime = fs.statSync(filePath).mtimeMs;
    if (newMtime !== lastMtime) {
      lastMtime = newMtime;
      fileVersion++;
      console.log(`  [v${fileVersion}] File changed externally (agent edit)`);
    }
  } catch {}
});

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://localhost:${port}`);

  // CORS for Vite dev server
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') { res.writeHead(204); res.end(); return; }

  if (url.pathname === '/api/scene.json') {
    const data = fs.readFileSync(filePath, 'utf8');
    res.writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-cache' });
    res.end(data);

  } else if (url.pathname === '/api/version') {
    res.writeHead(200, { 'Content-Type': 'text/plain', 'Cache-Control': 'no-cache' });
    res.end(String(fileVersion));

  } else if (url.pathname === '/api/save' && req.method === 'POST') {
    let body = '';
    req.on('data', (chunk) => { body += chunk; });
    req.on('end', () => {
      try {
        // Validate it's valid JSON
        const parsed = JSON.parse(body);
        if (parsed.type !== 'excalidraw') throw new Error('Not an excalidraw file');

        // Suppress watch events for our own write
        suppressWatchUntil = Date.now() + 2000;
        fs.writeFileSync(filePath, JSON.stringify(parsed, null, 2));
        lastMtime = fs.statSync(filePath).mtimeMs;

        console.log(`  [save] Browser edit → ${parsed.elements?.length || 0} elements written`);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ok: true }));
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: err.message }));
      }
    });

  } else {
    res.writeHead(404);
    res.end('Not found');
  }
});

server.listen(port, () => {
  console.log(`\n  Excalidraw API server: http://localhost:${port}`);
  console.log(`  File: ${filePath}`);
  console.log(`  Vite UI: http://localhost:${vitePort}\n`);

  if (autoOpen) {
    const cmd = process.platform === 'darwin' ? 'open' : 'xdg-open';
    exec(`${cmd} http://localhost:${vitePort}`, (err) => {
      if (err) console.log(`  Could not auto-open browser: ${err.message}`);
    });
  }
});
