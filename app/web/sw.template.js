/* GinBaby service worker: lưu sẵn app để mở và dùng được khi không có mạng.
   Tạo từ sw.template.js bởi tool/make_sw.py khi deploy (điền mã bản dựng và hai danh sách tệp [đường dẫn, mã băm, dung lượng]).
   Bộ nhớ đệm giữ nguyên giữa các bản: khi cập nhật chỉ tải những tệp có mã băm thay đổi. */
const STAMP = '__STAMP__';
const FILES_CACHE = 'ginbaby-files';
const META_CACHE = 'ginbaby-meta';
const CORE = __CORE__;   // đủ để mở app: mã, phông, CanvasKit
const REST = __REST__;   // ảnh minh hoạ và biến thể CanvasKit
const CORE_SIZE = CORE.reduce((a, f) => a + f[2], 0);
const GRAND = CORE_SIZE + REST.reduce((a, f) => a + f[2], 0);

function withTimeout(promise, ms) {
  return new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error('timeout')), ms);
    promise.then((v) => { clearTimeout(t); resolve(v); }, (err) => { clearTimeout(t); reject(err); });
  });
}

async function readMeta() {
  try {
    const c = await caches.open(META_CACHE);
    const r = await c.match('meta');
    return r ? await r.json() : { files: {} };
  } catch (_) { return { files: {} }; }
}

async function writeMeta(meta) {
  const c = await caches.open(META_CACHE);
  await c.put('meta', new Response(JSON.stringify(meta), { headers: { 'content-type': 'application/json' } }));
}

async function broadcast(msg) {
  for (const c of await self.clients.matchAll({ includeUncontrolled: true })) c.postMessage(msg);
}

// Đồng bộ một danh sách: bỏ qua tệp đã đủ (cùng mã băm), tải phần còn thiếu 4 tệp một lúc và thử lại tệp lỗi.
async function sync(list, phase, offset, grand) {
  offset = offset || 0;
  const cache = await caches.open(FILES_CACHE);
  const meta = await readMeta();
  const total = list.reduce((a, f) => a + f[2], 0);
  let done = 0, lastSent = 0;
  const todo = [];
  for (const f of list) {
    if (meta.files[f[0]] === f[1] && (await cache.match(f[0], { ignoreSearch: true }))) done += f[2];
    else todo.push(f);
  }
  const report = (force) => {
    const now = Date.now();
    if (force || now - lastSent > 250) { lastSent = now; broadcast({ type: 'progress', phase, done: offset + done, total: grand || total }); }
  };
  report(true);
  async function worker() {
    while (todo.length) {
      const f = todo.shift();
      let ok = false;
      for (let attempt = 0; attempt < 3 && !ok; attempt++) {
        try {
          const r = await withTimeout(fetch(new Request(f[0], { cache: 'reload' })), 60000);
          if (r.ok) { await cache.put(f[0], r); meta.files[f[0]] = f[1]; ok = true; }
        } catch (_) { /* thử lại */ }
        if (!ok) await new Promise((res) => setTimeout(res, 400 * (attempt + 1)));
      }
      if (ok) { done += f[2]; report(false); }
    }
  }
  await Promise.all([worker(), worker(), worker(), worker()]);
  await writeMeta(meta);
  report(true);
  return done >= total;
}

self.addEventListener('install', (e) => {
  e.waitUntil((async () => {
    await sync(CORE, 'core', 0, GRAND);
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (e) => {
  e.waitUntil((async () => {
    // Dọn bộ nhớ đệm cũ của các bản trước (tên theo mã bản dựng) và tệp không còn dùng
    for (const k of await caches.keys()) {
      if (k.startsWith('ginbaby-') && k !== FILES_CACHE && k !== META_CACHE) await caches.delete(k);
    }
    const keep = new Set(CORE.concat(REST).map((f) => new URL(f[0], self.location).pathname));
    const c = await caches.open(FILES_CACHE);
    for (const r of await c.keys()) {
      if (!keep.has(new URL(r.url).pathname) && !keep.has(new URL(r.url).pathname.replace(/\/$/, '/'))) await c.delete(r);
    }
    await self.clients.claim();
  })());
});

self.addEventListener('message', (e) => {
  const d = e.data || {};
  if (d.type === 'sync-all') {
    e.waitUntil((async () => {
      const okCore = await sync(CORE, 'core', 0, GRAND);
      const okRest = await sync(REST, 'rest', CORE_SIZE, GRAND);
      if (okCore && okRest) { const m = await readMeta(); m.stamp = STAMP; await writeMeta(m); }
      await broadcast({ type: 'synced', ok: okCore && okRest, stamp: STAMP });
    })());
  } else if (d.type === 'warm') {
    e.waitUntil((async () => { await sync(CORE, 'core', 0, GRAND); await sync(REST, 'rest', CORE_SIZE, GRAND); })());
  } else if (d.type === 'stamp') {
    if (e.source) e.source.postMessage({ type: 'stamp', stamp: STAMP });
  }
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== location.origin) return;
  // version.json và sw.js luôn lấy từ mạng; trang kiểm tra không qua bộ nhớ đệm
  if (/\/(version\.json|sw\.js|offline-check\.html)$/.test(url.pathname)) return;

  e.respondWith((async () => {
    const c = await caches.open(FILES_CACHE);
    if (req.mode === 'navigate') {
      // Mở app: có mạng và phản hồi tốt thì lấy bản mới nhất, nếu không (mất mạng, chậm hơn 3 giây, lỗi máy chủ) dùng bản đã lưu
      try {
        const r = await withTimeout(fetch(req), 3000);
        if (r.ok) return r;
      } catch (_) { /* dùng bản đã lưu */ }
      return (await c.match('index.html', { ignoreSearch: true })) || (await c.match('./', { ignoreSearch: true })) || Response.error();
    }
    const hit = await c.match(req, { ignoreSearch: true });
    if (hit) return hit;
    try {
      const r = await fetch(req);
      if (r.ok) c.put(req, r.clone());
      return r;
    } catch (_) {
      return Response.error();
    }
  })());
});
