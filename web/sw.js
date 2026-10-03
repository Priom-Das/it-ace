// IT-Ace service worker: makes the web app open offline.
// Bump CACHE_VERSION to force every user to drop old cached files.
const CACHE_VERSION = 'v1';
const CACHE = 'it-ace-' + CACHE_VERSION;

// App shell. Anything missing here is skipped, it will not break install.
const PRECACHE = [
  './',
  'index.html',
  'manifest.json',
  'favicon.png',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'flutter_bootstrap.js',
  'flutter.js',
  'main.dart.js',
  'assets/AssetManifest.bin.json',
  'assets/FontManifest.json',
];

const NETWORK_TIMEOUT_MS = 5000;

function isCacheable(url) {
  return url.origin === self.location.origin || url.hostname === 'fonts.gstatic.com';
}

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    await Promise.allSettled(PRECACHE.map(async (p) => {
      const res = await fetch(new Request(new URL(p, self.registration.scope), { cache: 'reload' }));
      if (res.ok) await cache.put(new URL(p, self.registration.scope), res);
    }));
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const names = await caches.keys();
    await Promise.all(names.filter((n) => n.startsWith('it-ace-') && n !== CACHE).map((n) => caches.delete(n)));
    await self.clients.claim();
  })());
});

// The page sends the list of files it already loaded, so the first visit is fully cached.
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'CACHE_URLS' && Array.isArray(event.data.urls)) {
    event.waitUntil(cacheUrls(event.data.urls));
  }
});

async function cacheUrls(urls) {
  const cache = await caches.open(CACHE);
  await Promise.allSettled(urls.map(async (u) => {
    const url = new URL(u);
    if (!isCacheable(url) || url.pathname.endsWith('/sw.js')) return;
    if (await cache.match(u)) return;
    const res = await fetch(u);
    if (res.ok) await cache.put(u, res);
  }));
}

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET' || req.headers.has('range')) return;
  const url = new URL(req.url);
  if (!isCacheable(url) || url.pathname.endsWith('/sw.js')) return; // Supabase/API calls pass through untouched

  if (req.mode === 'navigate') {
    event.respondWith(navigate(req));
  } else if (url.hostname === 'fonts.gstatic.com') {
    event.respondWith(cacheFirst(req));
  } else {
    event.respondWith(networkFirst(req));
  }
});

async function fetchWithTimeout(req) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), NETWORK_TIMEOUT_MS);
  try {
    return await fetch(req, { signal: controller.signal });
  } finally {
    clearTimeout(timer); // only limits the wait for response headers, not the download
  }
}

async function networkFirst(req) {
  const cache = await caches.open(CACHE);
  try {
    const res = await fetchWithTimeout(req);
    if (res && res.ok) cache.put(req, res.clone()).catch(() => {});
    return res;
  } catch (err) {
    const cached = await cache.match(req, { ignoreSearch: true });
    if (cached) return cached;
    throw err;
  }
}

async function cacheFirst(req) {
  const cache = await caches.open(CACHE);
  const cached = await cache.match(req);
  if (cached) return cached;
  const res = await fetch(req);
  if (res && res.ok) cache.put(req, res.clone()).catch(() => {});
  return res;
}

async function navigate(req) {
  const cache = await caches.open(CACHE);
  try {
    const res = await fetchWithTimeout(req);
    if (res && res.ok) cache.put(new URL('index.html', self.registration.scope), res.clone()).catch(() => {});
    return res;
  } catch (err) {
    const cached = (await cache.match(new URL('index.html', self.registration.scope))) ||
                   (await cache.match(new URL('./', self.registration.scope)));
    if (cached) return cached;
    throw err;
  }
}
