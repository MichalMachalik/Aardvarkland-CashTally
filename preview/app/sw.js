const scope = new URL(self.registration.scope);
const cachePrefix = `cashtally-preview:${scope.pathname}:`;
const cacheName = `${cachePrefix}28`;
const shell = new URL('index.html', scope);
const flags = 'eu in us id pk ng br ru mx jp eg tr th gb za kr dz ar ca ua pl my sa au ae cz se il hu ch dk no de fr it es nl be at bg pt gr fi ie sk hr lt si lv ee cy lu mt';
const assets = [
  './index.html', './app.css?brand=8', './flags.js?brand=3', './app.js?entry=mobile-preview-v12',
  './currency-data.js', './weight-data.js', './locales.js', './locale-overrides.js',
  './locale-extras.js', './locale-detail-extras.js', './locale-actions.js', './locale-report-extras.js',
  './locale-functional-extras.js?v=2', './manifest.webmanifest', './assets/aardvarkland-mark.png',
  './assets/materialicons-regular.otf',
  ...flags.split(' ').map((id) => `./assets/flags/${id}.svg`),
].map((path) => new URL(path, scope).href);
const cachedAssets = new Set(assets);

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(cacheName);
    await cache.addAll(assets.map((url) => new Request(url, { cache: 'reload' })));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    const expired = keys.filter((key) => key.startsWith(cachePrefix) && key !== cacheName);
    await Promise.all(expired.map((key) => caches.delete(key)));
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;
  const url = new URL(event.request.url);
  const isAppNavigation = event.request.mode === 'navigate' &&
    url.origin === scope.origin && [scope.pathname, shell.pathname].includes(url.pathname);
  if (!isAppNavigation && !cachedAssets.has(url.href)) return;
  event.respondWith((async () => {
    const cache = await caches.open(cacheName);
    const hit = await cache.match(isAppNavigation ? shell.href : event.request);
    return hit || fetch(event.request);
  })());
});
