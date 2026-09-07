(() => {
  'use strict';
  const adminId = '3be6094d-994e-4f8a-95db-7eb0cf602e32';
  const section = document.createElement('section');
  section.hidden = true;
  section.className = 'kh-card p-6 md:p-8 rounded-sm mb-8';
  section.innerHTML = `<h2 class="text-2xl font-black">홈페이지 방문 통계</h2>
    <p class="mt-2 text-sm text-slate-600">한국 시간 기준 · 관리자 전용</p>
    <form id="stats-filter" class="flex flex-wrap gap-3 items-end my-5">
      <label>시작일<input required type="date" id="stats-start" class="block border p-2 rounded"></label>
      <label>종료일<input required type="date" id="stats-end" class="block border p-2 rounded"></label>
      <button type="submit" class="px-4 py-2 kh-btn-primary rounded">조회</button>
      <button type="button" data-days="7" class="px-4 py-2 kh-btn-line rounded">최근 7일</button>
      <button type="button" data-days="30" class="px-4 py-2 kh-btn-line rounded">최근 30일</button>
    </form>
    <p id="stats-status" role="status" aria-live="polite"></p>
    <div id="stats-results"></div>
    <p class="mt-5 text-sm text-slate-500">방문자 수는 하루 동안 같은 브라우저의 중복을 제외한 추정치입니다. 기기 변경·저장소 차단에 따라 달라질 수 있습니다. 조회수는 페이지 열기·메뉴 이동·새로고침을 포함합니다. 자동 방문이나 차단된 기록 때문에 실제 사람 수와 다를 수 있습니다. 기록 시작 전 날짜는 집계 대상이 아닙니다.</p>`;
  document.getElementById('panel').prepend(section);
  const start = section.querySelector('#stats-start'), end = section.querySelector('#stats-end');
  const status = section.querySelector('#stats-status'), results = section.querySelector('#stats-results');
  let version = 0;
  let authorized = false;
  const names = {home:'홈',company:'회사소개',applications:'레이저 응용',inquiry_board:'상담문의',contact:'문의 작성',
    'products/fiber':'제품 · 파이버','products/uv':'제품 · UV','products/co2':'제품 · CO2','products/custom':'맞춤형 장비'};
  const escape = v => String(v).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  function range(days) {
    end.value = new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Seoul',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date());
    const date = new Date(end.value+'T00:00:00Z'); date.setUTCDate(date.getUTCDate()-days+1); start.value=date.toISOString().slice(0,10);
  }
  async function load() {
    const request = ++version;
    results.replaceChildren();
    if (!authorized) return;
    const span = (new Date(end.value)-new Date(start.value))/86400000;
    if (!Number.isFinite(span) || span<0 || span>365) {status.textContent='시작일과 종료일을 확인하세요. 최대 366일까지 조회할 수 있습니다.';return;}
    status.textContent='방문 통계를 불러오는 중입니다…';
    try {
      const {data,error} = await supabaseClient.rpc('get_visit_statistics',{p_start:start.value,p_end:end.value});
      if (request!==version || !authorized) return;
      if (error) throw error;
      const daily=data.daily||[], pages=data.pages||[];
      const total=daily.reduce((sum,row)=>sum+Number(row.views),0);
      const people=daily.reduce((sum,row)=>sum+Number(row.visitors),0);
      const max=Math.max(1,...daily.map(row=>Number(row.views)));
      status.textContent=data.started_on ? `기록 시작일: ${data.started_on} · 선택 기간 ${total.toLocaleString('ko-KR')}회 조회` : '아직 수집된 방문 기록이 없습니다.';
      results.innerHTML=`<div class="grid md:grid-cols-2 gap-4 mb-5"><div class="bg-slate-50 p-4">페이지 조회수<strong class="block text-3xl mt-2">${total.toLocaleString('ko-KR')}</strong></div><div class="bg-slate-50 p-4">일별 방문자 수 합계<strong class="block text-3xl mt-2">${people.toLocaleString('ko-KR')}</strong><span class="text-sm">서로 다른 날짜의 같은 방문자는 중복됩니다.</span></div></div>
        <div class="overflow-auto" style="max-height:480px"><table class="w-full text-left"><caption class="text-left font-bold py-3">날짜별 방문 현황</caption><thead><tr><th class="p-2">날짜</th><th class="p-2">방문자</th><th class="p-2">조회수</th><th class="p-2">조회 추이</th></tr></thead><tbody>${daily.slice().reverse().map(row=>`<tr class="border-t"><td class="p-2 whitespace-nowrap">${escape(row.day)}</td><td class="p-2">${data.started_on&&row.day>=data.started_on?Number(row.visitors):'—'}</td><td class="p-2">${data.started_on&&row.day>=data.started_on?Number(row.views):'—'}</td><td class="p-2" style="width:40%"><div aria-hidden="true" style="height:12px;background:#005bac;width:${Math.max(0,Number(row.views)/max*100)}%"></div></td></tr>`).join('')}</tbody></table></div>
        <h3 class="font-bold mt-6 mb-2">페이지별 조회수</h3><table class="w-full text-left"><thead><tr><th class="p-2">페이지</th><th class="p-2">조회수</th></tr></thead><tbody>${pages.map(row=>`<tr class="border-t"><td class="p-2">${escape(names[row.page]||row.page)}</td><td class="p-2">${Number(row.views)}</td></tr>`).join('')}</tbody></table>`;
    } catch (_) {if(request===version) status.textContent='통계를 불러오지 못했습니다. 관리자 로그인 상태를 확인하고 다시 조회해 주세요.';}
  }
  function sessionChanged(session) {
    authorized=!!session&&session.user.id===adminId; section.hidden=!authorized;
    ++version; results.replaceChildren(); status.textContent='';
    if(authorized) void load();
  }
  section.querySelector('form').addEventListener('submit',event=>{event.preventDefault();void load();});
  section.querySelectorAll('[data-days]').forEach(button=>button.addEventListener('click',()=>{range(Number(button.dataset.days));void load();}));
  range(30);
  supabaseClient.auth.onAuthStateChange((_event,session)=>setTimeout(()=>sessionChanged(session),0));
  supabaseClient.auth.getSession().then(({data})=>sessionChanged(data.session));
})();
