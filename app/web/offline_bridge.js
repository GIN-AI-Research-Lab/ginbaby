// Cầu nối cho màn "Kiểm tra chế độ ngoại tuyến" trong app (Dart gọi các hàm này)
window.ginbabyOfflineStatus = async function () {
  const out = {
    standalone: (navigator.standalone === true) || matchMedia('(display-mode: standalone)').matches,
    hasSW: 'serviceWorker' in navigator,
  };
  const reg = out.hasSW ? await navigator.serviceWorker.getRegistration() : null;
  out.sw = reg ? (reg.active ? 'active:' + reg.active.state : reg.installing ? 'installing' : reg.waiting ? 'waiting' : 'unknown') : 'none';
  out.controlled = out.hasSW && !!navigator.serviceWorker.controller;
  // Bộ nhớ ngoại tuyến giữ nguyên giữa các bản: so mã băm từng tệp đã lưu với danh sách của bản mới nhất
  let meta = { files: {}, stamp: '' };
  try {
    const mc = await caches.open('ginbaby-meta');
    const r = await mc.match('meta');
    if (r) meta = await r.json();
  } catch (e) {}
  out.cache = meta.stamp ? 'ginbaby-' + meta.stamp : '';
  try {
    const t = await (await fetch('sw.js', { cache: 'no-store' })).text();
    const core = JSON.parse(/const CORE = (\[.*?\]);/s.exec(t)[1]);
    const rest = JSON.parse(/const REST = (\[.*?\]);/s.exec(t)[1]);
    out.latest = 'ginbaby-' + /const STAMP = '([^']+)'/.exec(t)[1];
    const ok = function (f) { return meta.files[f[0]] === f[1]; };
    out.core = core.length;
    out.rest = rest.length;
    out.coreOk = core.filter(ok).length;
    out.restOk = rest.filter(ok).length;
    out.missing = core.filter(function (f) { return !ok(f); }).map(function (f) { return f[0]; }).slice(0, 8);
  } catch (e) {
    out.offline = true;
  }
  try {
    const est = await navigator.storage.estimate();
    out.usedMb = Math.round(est.usage / 1e6);
    out.persisted = await navigator.storage.persisted();
  } catch (e) {}
  return JSON.stringify(out);
};

window.ginbabyOfflineWarm = async function () {
  const reg = await navigator.serviceWorker.getRegistration();
  if (reg) {
    await reg.update();
    const w = reg.active || reg.waiting || reg.installing;
    if (w) w.postMessage({ type: 'warm' });
  }
};

window.ginbabyOfflineReset = async function () {
  for (const r of await navigator.serviceWorker.getRegistrations()) await r.unregister();
  for (const k of await caches.keys()) await caches.delete(k);
  await navigator.serviceWorker.register('sw.js');
  await navigator.serviceWorker.ready;
  const reg = await navigator.serviceWorker.getRegistration();
  if (reg && reg.active) reg.active.postMessage({ type: 'warm' });
};
