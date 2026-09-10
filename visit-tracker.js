/* First-party page statistics. No raw URLs, referrers or inquiry fields are sent. */
(() => {
  'use strict';
  if (!['www.kooky.co.kr', 'kooky.co.kr'].includes(location.hostname)) return;
  const endpoint = 'https://kzbchskpscdyzwqqcqhk.supabase.co/rest/v1/rpc/record_page_view';
  const apiKey = 'sb_publishable_WBqZIpbSfr1_J1xieoIzzA_R9AWhzJu';
  const adminId = '3be6094d-994e-4f8a-95db-7eb0cf602e32';
  const authStorageKey = 'sb-kzbchskpscdyzwqqcqhk-auth-token';
  const botPattern = /bot|crawler|spider|slurp|bingpreview|headless|lighthouse|pagespeed|facebookexternalhit|whatsapp|telegrambot|kakaotalk-scrap|naverbot|yeti|daum|zumBot/i;
  let lastPage = '';
  let memoryVisitor;
  const excluded = ['admin.html','inquiry-detail.html','inquiry-check.html'];
  function isAutomatedVisitor() {
    return navigator.webdriver === true || botPattern.test(navigator.userAgent || '');
  }
  function isAdminViewer() {
    try {
      const saved = JSON.parse(localStorage.getItem(authStorageKey) || 'null');
      return saved?.user?.id === adminId;
    } catch (_) {
      return false;
    }
  }
  const day = () => new Intl.DateTimeFormat('en-CA', {timeZone:'Asia/Seoul',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date());
  function visitor() {
    const today = day();
    try {
      const previous = JSON.parse(localStorage.getItem('kh_visit_daily_v1') || 'null');
      if (previous && previous.day === today && /^[0-9a-f-]{36}$/.test(previous.id)) return previous.id;
      memoryVisitor = {day:today,id:crypto.randomUUID()};
      localStorage.setItem('kh_visit_daily_v1', JSON.stringify(memoryVisitor));
    } catch (_) {
      if (!memoryVisitor || memoryVisitor.day !== today) memoryVisitor = {day:today,id:crypto.randomUUID()};
    }
    return memoryVisitor.id;
  }
  function page() {
    const file = decodeURIComponent(location.pathname.split('/').pop() || '');
    if (excluded.includes(file)) return '';
    if (['','index.html','index (1).html'].includes(file)) {
      const params = new URLSearchParams(location.search);
      const section = params.get('section') || 'home';
      if (section === 'products') {
        const category = params.get('category') || 'fiber';
        return 'products/' + (['fiber','uv','co2','custom'].includes(category) ? category : 'fiber');
      }
      return ['home','company','applications','inquiry_board','contact'].includes(section) ? section : 'home';
    }
    return file;
  }
  function record() {
    if (document.visibilityState !== 'visible') return;
    if (isAutomatedVisitor() || isAdminViewer()) return;
    try {
      const current = page();
      if (!current || current === lastPage) return;
      lastPage = current;
      fetch(endpoint, {method:'POST',headers:{apikey:apiKey,'Content-Type':'application/json'},
        body:JSON.stringify({p_event_id:crypto.randomUUID(),p_visitor_id:visitor(),p_page:current}),
        keepalive:true,credentials:'omit'}).catch(() => {});
    } catch (_) { /* Statistics must never interrupt browsing. */ }
  }
  ['pushState','replaceState'].forEach(name => {
    const original = history[name];
    history[name] = function(...args) { const result = original.apply(this,args); queueMicrotask(record); return result; };
  });
  addEventListener('popstate',record);
  document.addEventListener('visibilitychange',record);
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded',record); else record();
})();
