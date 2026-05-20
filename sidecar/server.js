// Sidecar service: exposes POST /search { description } → JSON matches.
// Runs puppeteer-extra+stealth in its OWN Node process (no n8n sandbox).
const http = require('http');
const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
puppeteer.use(StealthPlugin());

const PORT = process.env.SEARCH_PORT || 8765;

async function doSearch(description, city) {
  const browser = await puppeteer.launch({
    executablePath: process.env.PUPPETEER_EXECUTABLE_PATH || '/usr/bin/chromium',
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--disable-blink-features=AutomationControlled'],
  });
  try {
    const page = await browser.newPage();
    await page.setViewport({ width: 1280, height: 800 });
    await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36');
    await page.setExtraHTTPHeaders({ 'accept-language': 'pt-BR,pt;q=0.9,en;q=0.8' });
    await page.goto('https://sites.appbarber.com.br/', { waitUntil: 'networkidle2', timeout: 60000 });
    await new Promise(r => setTimeout(r, 1500));
    const apiResult = await page.evaluate(async (q) => {
      const r = await fetch(`/api/new-establishment-search?description=${encodeURIComponent(q)}`, { headers: { accept: 'application/json' } });
      if (!r.ok) return { __error: `HTTP ${r.status}` };
      return { status: r.status, body: await r.json() };
    }, description);
    if (apiResult.__error) return { matches: [], error: apiResult.__error };
    const data = apiResult.body;
    let matches = Array.isArray(data?.establishments) ? data.establishments : [];
    if (city) {
      const lc = String(city).toLowerCase();
      const filt = matches.filter(m => String(m.establishment_city_name||'').toLowerCase().includes(lc));
      if (filt.length) matches = filt;
    }
    matches = matches.slice(0, 5).map(m => ({
      id: m.establishment_code,
      name: m.establishment_name,
      city: m.establishment_city_name,
      abbreviation: m.establishment_abbreviation,
      address: m.establishment_address,
      phone: m.establishment_phone,
      image: m.establishment_image,
      latitude: m.establishment_latitude,
      longitude: m.establishment_longitude,
      raw: m,
    }));
    return { matches };
  } finally {
    await browser.close();
  }
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'GET' && req.url === '/health') {
    res.writeHead(200, {'Content-Type':'application/json'});
    res.end('{"status":"ok"}');
    return;
  }
  if (req.method !== 'POST' || !req.url.startsWith('/search')) {
    res.writeHead(404); res.end('not found'); return;
  }
  let body = '';
  req.on('data', c => body += c);
  req.on('end', async () => {
    try {
      const j = body ? JSON.parse(body) : {};
      const desc = String(j.description || j.q || '').trim();
      if (!desc) { res.writeHead(400, {'Content-Type':'application/json'}); res.end('{"error":"description required"}'); return; }
      const result = await doSearch(desc, j.city);
      res.writeHead(200, {'Content-Type':'application/json'});
      res.end(JSON.stringify(result));
    } catch (e) {
      res.writeHead(500, {'Content-Type':'application/json'});
      res.end(JSON.stringify({ error: e.message, stack: (e.stack||'').slice(0, 300) }));
    }
  });
});
server.listen(PORT, '0.0.0.0', () => console.log(`[search-svc] listening on ${PORT}`));
