/* analizodatos.com · medición propia con cookies PROPIAS (sin terceros ni publicidad). ~2,4 KB.
   Cookies: _ad_vid = id aleatorio de visitante (400 días) para contar visitantes únicos; _ad_ses = id de sesión (se borra al cerrar
   el navegador); _ad_own = marca «soy Manu» (la activa /yo) que excluye mis visitas de las cifras.
   Qué envía: página vista, tiempo ACTIVO en la página (pestaña visible), profundidad de scroll y clics a otros sitios.
   Qué NO hace: no guarda query strings ni el contenido de la página, no usa cookies de terceros y se apaga solo si el navegador
   pide Do Not Track o Global Privacy Control (en ese caso tampoco crea cookies).
   Los eventos se guardan 90 días. Detalle: https://analizodatos.com/privacidad/ */
(function () {
  try {
    var n = navigator;
    if (n.doNotTrack === '1' || window.doNotTrack === '1' || n.globalPrivacyControl) return;
    var tag = document.currentScript;
    var EP = (tag && tag.getAttribute('data-endpoint')) || '/t/e';   // mismo origen (Función de Cloudflare); en otros sitios: la URL pública de la API
    var C = 'abcdefghijklmnopqrstuvwxyz0123456789';
    var id = function () {
      var a = '', i;
      try { var r = crypto.getRandomValues(new Uint8Array(16)); for (i = 0; i < 16; i++) a += C[r[i] % 36]; }
      catch (e) { for (i = 0; i < 16; i++) a += C[Math.floor(Math.random() * 36)]; }
      return a;
    };
    var host = location.hostname.toLowerCase();
    // las cookies se comparten entre analizodatos.com y sus subdominios; en otros sitios quedan solo en ese host
    var DOM = /(^|\.)analizodatos\.com$/.test(host) ? ';domain=.analizodatos.com' : '';
    var SEC = location.protocol === 'https:' ? ';Secure' : '';
    function getC(k) { try { var m = document.cookie.match(new RegExp('(?:^|; )' + k + '=([^;]*)')); return m ? decodeURIComponent(m[1]) : ''; } catch (e) { return ''; } }
    function setC(k, v, dias) { try { document.cookie = k + '=' + encodeURIComponent(v) + ';path=/;SameSite=Lax' + SEC + DOM + (dias ? ';max-age=' + dias * 86400 : ''); } catch (e) { } }
    var OKID = /^[A-Za-z0-9_-]{8,40}$/;
    var vid = getC('_ad_vid'); if (!OKID.test(vid)) vid = id();
    setC('_ad_vid', vid, 400);                       // se renueva en cada visita (máximo que permiten los navegadores: 400 días)
    var sid = getC('_ad_ses');
    if (!OKID.test(sid)) {
      sid = '';
      try { sid = sessionStorage.getItem('_ad_sid') || ''; } catch (e) { }   // respaldo si las cookies están bloqueadas
      if (!OKID.test(sid)) { sid = id(); try { sessionStorage.setItem('_ad_sid', sid); } catch (e) { } }
    }
    setC('_ad_ses', sid, 0);                         // cookie de sesión: sin max-age
    var own = getC('_ad_own') === '1' ? 1 : 0;
    var pv = id(), path = location.pathname;
    var bare = function (h) { return h.replace(/^www\./, ''); };

    function send(o) {
      o.pv = pv; o.sid = sid; o.vid = vid; if (own) o.own = 1; o.host = host; o.path = path; o.lang = n.language || '';
      var b = JSON.stringify(o);
      try { if (n.sendBeacon && n.sendBeacon(EP, new Blob([b], { type: 'text/plain' }))) return; } catch (e) { }
      try { fetch(EP, { method: 'POST', body: b, keepalive: true, mode: 'no-cors', headers: { 'Content-Type': 'text/plain' } }); } catch (e) { }
    }

    var active = 0, last = document.hidden ? 0 : Date.now(), maxScroll = 0;
    function tick() { if (last) { var t = Date.now(); active += t - last; last = t; } }
    function scroll() {
      var h = document.documentElement, tot = h.scrollHeight - h.clientHeight;
      var p = tot > 0 ? Math.round(100 * (window.scrollY || h.scrollTop) / tot) : 100;
      if (p > maxScroll) maxScroll = Math.min(p, 100);
    }
    function ping() { tick(); scroll(); send({ kind: 'ping', active_ms: active, scroll: maxScroll }); }

    send({ kind: 'view', ref: document.referrer });
    addEventListener('scroll', scroll, { passive: true }); scroll();
    document.addEventListener('visibilitychange', function () { if (document.hidden) { ping(); last = 0; } else { last = Date.now(); } });
    addEventListener('pagehide', ping);
    // cada 5 s durante los primeros 30 s (visitas cortas: el último ping al salir puede perderse) y luego cada 15 s
    var t0 = Date.now();
    (function loop() {
      setTimeout(function () { if (!document.hidden) ping(); loop(); }, Date.now() - t0 < 30000 ? 5000 : 15000);
    })();

    // clics a otros sitios (incluidos otros subdominios propios): «hipervínculos desde aquí»
    document.addEventListener('click', function (e) {
      var a = e.target && e.target.closest && e.target.closest('a[href]'); if (!a) return;
      var u; try { u = new URL(a.href, location.href); } catch (x) { return; }
      if (/^https?:$/.test(u.protocol) && u.hostname.toLowerCase() !== host) {
        send({ kind: 'click', url: u.origin + u.pathname, text: (a.textContent || a.getAttribute('aria-label') || '').trim().slice(0, 80) });
      }
    }, true);
  } catch (e) { /* la medición nunca debe romper la página */ }
})();
