{{flutter_js}}
{{flutter_build_config}}

// No serviceWorkerSettings here on purpose: newer Flutter would register its own
// self-removing worker and it would replace our sw.js.
_flutter.loader.load();

if ('serviceWorker' in navigator) {
  const startServiceWorker = async () => {
    try {
      await navigator.serviceWorker.register('sw.js');
      const reg = await navigator.serviceWorker.ready;
      // Ask the worker to cache everything the page has loaded so far (after Flutter finished starting).
      const sendLoadedFiles = () => {
        const urls = performance.getEntriesByType('resource').map((r) => r.name);
        urls.push(new URL('index.html', document.baseURI).href);
        if (reg.active) reg.active.postMessage({ type: 'CACHE_URLS', urls });
      };
      setTimeout(sendLoadedFiles, 5000);
      setTimeout(sendLoadedFiles, 15000);
    } catch (e) {
      console.warn('Service worker registration failed:', e);
    }
  };
  if (document.readyState === 'complete') startServiceWorker();
  else window.addEventListener('load', startServiceWorker);
}
