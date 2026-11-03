# Updates the TV screenshot script on WEB03 (wrapper now auto-refreshes the image every 60s, no stale cache)
$enc = New-Object System.Text.UTF8Encoding($false)
if (Test-Path 'C:\millboard\screenshot-github.js') { Copy-Item 'C:\millboard\screenshot-github.js' 'C:\millboard\screenshot-github.js.bak' -Force }

[IO.File]::WriteAllText('C:\millboard\screenshot-github.js', @'
/* =====================================================================
   Mill board -> screenshots -> GitHub (for the Appspace TV)
   Location : C:\millboard\screenshot-github.js   (JSW-WEB03)
   Run by   : PM2 process "mill-screenshot-github", cron 5,20,35,50 * * * *

   Every run:
     1. Old board  -> snapshot.png + index.html     (existing TV card, unchanged)
     2. Plate pace -> plate.png    + plate.html
     3. Pipe pace  -> pipe.png     + pipe.html

   ------------------------------ SWITCHES ------------------------------ */

const AS_OF         = '2026-10-31';  // demo date. Set to '' for LIVE data (after the SQL job is running)
const CAPTURE_OLD   = false;         // old board no longer captured (not in use)

/* ------------------------------ SETTINGS ------------------------------ */

const DASH_URL   = 'http://localhost:3002';   // Node serves the board + API directly (no IIS / cert)
const OWNER      = 'smundhada';
const REPO       = 'sw-mill-board';
const BRANCH     = 'main';
const OUT_DIR    = 'C:\\millboard\\screenshots';
const TOKEN_FILE = 'C:\\millboard\\github-token.txt';   // one line: the GitHub token. NOT in the repo.

/* ---------------------------------------------------------------------- */

const fs        = require('fs');
const path      = require('path');
const https     = require('https');
const puppeteer = require('puppeteer');

const RAW = `https://raw.githubusercontent.com/${OWNER}/${REPO}/${BRANCH}`;

function log(...a) { console.log(new Date().toISOString(), ...a); }

function getToken() {
  if (process.env.GITHUB_TOKEN) return process.env.GITHUB_TOKEN.trim();
  if (fs.existsSync(TOKEN_FILE)) return fs.readFileSync(TOKEN_FILE, 'utf8').trim();
  throw new Error(`No GitHub token. Put it in ${TOKEN_FILE} or set GITHUB_TOKEN.`);
}

/* ---------- GitHub contents API ---------- */
function gh(method, apiPath, token, body) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const req = https.request({
      hostname: 'api.github.com',
      path: apiPath,
      method,
      headers: {
        'User-Agent': 'mill-board-screenshot',
        'Accept': 'application/vnd.github+json',
        'Authorization': `Bearer ${token}`,
        ...(data ? { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(data) } : {})
      }
    }, res => {
      let chunks = '';
      res.on('data', c => (chunks += c));
      res.on('end', () => resolve({ status: res.statusCode, json: chunks ? JSON.parse(chunks) : {} }));
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

async function pushFile(token, repoPath, buffer) {
  const api = `/repos/${OWNER}/${REPO}/contents/${repoPath}`;
  const existing = await gh('GET', `${api}?ref=${BRANCH}`, token);
  const sha = existing.status === 200 ? existing.json.sha : undefined;

  const res = await gh('PUT', api, token, {
    message: `TV update ${repoPath} ${new Date().toISOString()}`,
    content: buffer.toString('base64'),
    branch: BRANCH,
    ...(sha ? { sha } : {})
  });
  if (res.status !== 200 && res.status !== 201) {
    throw new Error(`GitHub push failed for ${repoPath}: ${res.status} ${JSON.stringify(res.json).slice(0, 200)}`);
  }
  log('pushed', repoPath);
}

/* ---------- wrapper pages (cache-busted image URL so Appspace always shows the newest) ---------- */
function imagePage(img, stamp) {
  // The <img> is reloaded every 60s by JS with a fresh ?t=, so the display
  // always pulls the newest PNG and never shows a cached/stale copy.
  return `<!doctype html>
<html><head><meta charset="utf-8">
<style>html,body{margin:0;height:100%;background:#e9edf2}img{width:100%;height:100%;object-fit:contain;display:block}</style>
</head><body><img id="s" alt="">
<script>
  var base = "${RAW}/${img}";
  function refresh() { document.getElementById('s').src = base + "?t=" + Date.now(); }
  refresh();
  setInterval(refresh, 60000);
</script></body></html>`;
}

/* ---------- capture ---------- */
async function capture(browser, url, file, waitFor) {
  const page = await browser.newPage();
  try {
    await page.setViewport({ width: 1920, height: 1080 });
    await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 });
    await waitFor(page);
    await new Promise(r => setTimeout(r, 800));           // let fonts/arcs settle
    const out = path.join(OUT_DIR, file);
    await page.screenshot({ path: out });
    log('captured', file, '<-', url);
    return fs.readFileSync(out);
  } finally {
    await page.close();
  }
}

// pace page is ready when the expected number of cards (with gauges) is on screen
const waitForCards = (n) => (page) =>
  page.waitForFunction(
    (count) => document.querySelectorAll('.pb-card .pb-gauge svg').length >= count,
    { timeout: 45000 }, n);

// old board is ready when its chart canvases exist
const waitForOld = (page) =>
  page.waitForSelector('canvas', { timeout: 45000 }).then(() => new Promise(r => setTimeout(r, 2500)));

/* ---------- main ---------- */
(async () => {
  const started = Date.now();
  let browser;
  try {
    const token = getToken();
    if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });

    browser = await puppeteer.launch({
      headless: true,
      args: ['--ignore-certificate-errors', '--no-sandbox', '--disable-gpu']
    });

    const q     = AS_OF ? `&asOf=${AS_OF}` : '';
    const stamp = Date.now();
    const files = [];

    if (CAPTURE_OLD) {
      const png = await capture(browser, DASH_URL, 'snapshot.png', waitForOld);
      files.push(['snapshot.png', png], ['index.html', Buffer.from(imagePage('snapshot.png', stamp))]);
    }

    const plate = await capture(browser, `${DASH_URL}/?mill=plate${q}`, 'plate.png', waitForCards(2));
    const pipe  = await capture(browser, `${DASH_URL}/?mill=pipe${q}`,  'pipe.png',  waitForCards(3));

    files.push(
      ['plate.png', plate], ['plate.html', Buffer.from(imagePage('plate.png', stamp))],
      ['pipe.png',  pipe],  ['pipe.html',  Buffer.from(imagePage('pipe.png',  stamp))]
    );

    await browser.close(); browser = null;

    for (const [name, buf] of files) await pushFile(token, name, buf);   // one at a time: avoids sha conflicts

    log(`done in ${((Date.now() - started) / 1000).toFixed(1)}s`, AS_OF ? `(DEMO asOf=${AS_OF})` : '(LIVE)');
    process.exit(0);
  } catch (err) {
    log('ERROR', err.message);
    if (browser) await browser.close().catch(() => {});
    process.exit(1);   // nothing half-pushed for the failed capture; next run retries
  }
})();
'@, $enc)
Write-Host 'wrote C:\millboard\screenshot-github.js'

Write-Host 'Done. Now run: node screenshot-github.js   (to push updated wrappers)' -ForegroundColor Green
