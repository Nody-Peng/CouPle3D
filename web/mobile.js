'use strict';
(() => {
  const enabled = matchMedia('(pointer: coarse)').matches;
  if (!enabled) return;
  document.body.classList.add('touch-device');
  const root = document.createElement('div');
  root.id = 'mobile-controls';
  root.hidden = true;
  root.innerHTML = `
    <header class="mobile-bar"><button id="mobile-menu" type="button">選單</button><span id="mobile-status" role="status">正在回家</span><span id="mobile-coins"></span><button id="mobile-zoom" type="button" aria-label="切換鏡頭遠近" title="切換鏡頭遠近">＋ / −</button><button id="mobile-fullscreen" type="button" aria-label="全螢幕" title="全螢幕">⛶</button></header>
    <div id="mobile-stick" role="group" aria-label="移動搖桿"><span id="mobile-knob"></span></div>
    <button id="mobile-action" type="button" disabled>互動</button>
    <p id="mobile-toast" role="status" hidden></p>
    <div id="mobile-portrait" hidden><span aria-hidden="true">↻</span><p>請將手機轉成橫向</p></div>
    <dialog id="mobile-dialog" aria-labelledby="mobile-title"><header><h2 id="mobile-title"></h2><button id="mobile-close" type="button" aria-label="關閉">×</button></header><div id="mobile-content"></div><p id="mobile-feedback" role="status"></p><p id="mobile-error" role="alert"></p></dialog>`;
  document.body.append(root);
  const el = id => document.getElementById(id);
  const dialog = el('mobile-dialog'), content = el('mobile-content');
  const stick = el('mobile-stick'), knob = el('mobile-knob');
  let entered = false, portrait = false, suspended = false, pointer = null;
  let x = 0, y = 0, commands = [], page = '', snapshot = null, generation = 0, pending = false;
  let pollBusy = false, toastTimer, feed;
  function stop() {
    if (pointer !== null && stick.hasPointerCapture(pointer)) stick.releasePointerCapture(pointer);
    pointer = null; x = 0; y = 0;
    commands = [];
    knob.style.transform = 'translate(-50%, -50%)';
  }
  function blocked() { return !entered || portrait || suspended || document.hidden || dialog.open; }
  function layout() {
    if (!dialog.open) portrait = innerWidth < innerHeight;
    el('mobile-portrait').hidden = !portrait || dialog.open;
    const viewport = window.visualViewport;
    document.documentElement.style.setProperty('--mobile-dialog-height', `${Math.max(140, (viewport?.height || innerHeight) - 16)}px`);
    document.documentElement.style.setProperty('--mobile-dialog-top', `${(viewport?.offsetTop || 0) + 8}px`);
    stop();
  }
  window.homeMobile = {
    enabled, state: {},
    consume() {
      const paused = blocked();
      const result = {x: paused ? 0 : x, y: paused ? 0 : y, blocked: paused, commands: paused ? [] : commands,
        height: Math.round(960 * innerHeight / Math.max(1, innerWidth))};
      commands = [];
      return result;
    },
    openPanel,
    toast(message) {
      if (dialog.open) el('mobile-feedback').textContent = message;
      el('mobile-toast').textContent = message;
      el('mobile-toast').hidden = false;
      clearTimeout(toastTimer);
      toastTimer = setTimeout(() => { el('mobile-toast').hidden = true; }, 3500);
    }
  };
  function enter() { entered = true; root.hidden = false; document.body.classList.add('mobile-playing'); layout(); }
  window.addEventListener('home:entered', enter);
  if (!el('game').hidden) enter();
  window.addEventListener('resize', layout);
  window.visualViewport?.addEventListener('resize', layout);
  window.addEventListener('blur', () => { suspended = true; stop(); });
  window.addEventListener('focus', () => { suspended = false; });
  document.addEventListener('visibilitychange', () => { stop(); });
  window.addEventListener('pagehide', stop);
  root.addEventListener('pointerdown', () => { suspended = false; }, {capture: true});
  function move(event) {
    const rect = stick.getBoundingClientRect();
    const dx = event.clientX - rect.left - rect.width / 2, dy = event.clientY - rect.top - rect.height / 2;
    const radius = rect.width * 0.32, length = Math.hypot(dx, dy);
    const scale = length > radius ? radius / length : 1;
    x = length < 8 ? 0 : dx * scale / radius;
    y = length < 8 ? 0 : dy * scale / radius;
    knob.style.transform = `translate(calc(-50% + ${dx * scale}px), calc(-50% + ${dy * scale}px))`;
  }
  stick.addEventListener('pointerdown', event => {
    if (pointer !== null || blocked() || !window.homeMobile.state.connected) return;
    event.preventDefault(); pointer = event.pointerId; stick.setPointerCapture(pointer); move(event);
  });
  stick.addEventListener('pointermove', event => { if (event.pointerId === pointer) { event.preventDefault(); move(event); } });
  for (const type of ['pointerup', 'pointercancel', 'lostpointercapture']) {
    stick.addEventListener(type, event => { if (event.pointerId === pointer) stop(); });
  }
  el('mobile-action').onclick = () => { if (!blocked()) commands.push('interact'); };
  el('mobile-zoom').onclick = () => { if (!blocked()) commands.push('zoom'); };
  el('mobile-menu').onclick = () => openPanel('menu');
  el('mobile-close').onclick = close;
  dialog.addEventListener('cancel', event => { event.preventDefault(); close(); });
  dialog.addEventListener('click', event => { if (event.target === dialog) {
    const r = dialog.getBoundingClientRect();
    if (event.clientX < r.left || event.clientX > r.right || event.clientY < r.top || event.clientY > r.bottom) close();
  } });
  el('mobile-fullscreen').hidden = !document.fullscreenEnabled;
  el('mobile-fullscreen').onclick = async () => {
    try { if (document.fullscreenElement) await document.exitFullscreen(); else await document.documentElement.requestFullscreen(); }
    catch { window.homeMobile.toast('此瀏覽器暫時無法切換全螢幕'); }
  };
  function close() { generation++; page = ''; dialog.close(); stop(); layout(); }
  function node(tag, text, parent = content) {
    const element = document.createElement(tag);
    if (text !== undefined) element.textContent = text;
    parent.append(element); return element;
  }
  function button(text, action, parent = content) {
    const element = node('button', text, parent); element.type = 'button';
    element.onclick = async () => {
      if (pending) return;
      pending = true; element.disabled = true; el('mobile-error').textContent = '';
      try { await action(); } catch (error) { el('mobile-error').textContent = error.message; }
      finally { pending = false; if (element.isConnected) element.disabled = false; }
    };
    return element;
  }
  function field(label, value = '', max = 300, multiline = false) {
    const wrapper = node('label', label);
    const input = node(multiline ? 'textarea' : 'input', undefined, wrapper);
    input.value = value; input.maxLength = max;
    if (multiline) input.rows = 3;
    else input.type = 'text';
    input.autocomplete = 'off'; return input;
  }
  async function request(data) {
    const response = await fetch('/api/home2d', data ? {method: 'POST', credentials: 'same-origin', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(data)} : {credentials: 'same-origin', cache: 'no-store'});
    const result = await response.json();
    if (!response.ok) throw new Error(result.error || '暫時無法同步，請稍後再試');
    return result;
  }
  async function openPanel(key) {
    stop();
    page = key; feed = null;
    const token = ++generation;
    content.replaceChildren(); el('mobile-error').textContent = ''; el('mobile-feedback').textContent = '';
    el('mobile-title').textContent = {menu: '共同之家', connect: '我的角色', chat: '聊天', diary: '共同日記', note: '冰箱便條', shop: '生活選物', date: '下一次約會', hug: '抱抱', cards: '默契卡'}[key] || key;
    if (!dialog.open) dialog.showModal();
    layout();
    if (key === 'menu') {
      const menu = node('nav'); menu.className = 'mobile-menu-grid';
      for (const [label, target] of [['聊天','chat'],['日記','diary'],['家具','shop'],['約會','date'],['抱抱','hug'],['默契','cards'],['我的角色','connect']]) button(label, () => openPanel(target), menu);
      button('合照', () => { close(); commands.push('photo'); }, menu);
      button('登出', () => { close(); el('logout').click(); });
      return;
    }
    const loading = node('p', '正在同步…');
    try {
      const result = await request();
      if (token !== generation || !dialog.open) return;
      snapshot = result; loading.remove(); render(key);
    } catch (error) { if (token === generation) { loading.remove(); el('mobile-error').textContent = error.message; button('重試', () => openPanel(key)); } }
  }
  function updateFeed(state) {
    if (!feed) return;
    const pinned = feed.scrollHeight - feed.scrollTop - feed.clientHeight < 32;
    const entries = page === 'chat' ? state.messages : state.diary;
    const signature = JSON.stringify(entries);
    if (feed.dataset.signature === signature) return;
    feed.dataset.signature = signature; feed.replaceChildren();
    if (!entries.length) node('p', page === 'chat' ? '還沒有訊息' : '還沒有日記', feed);
    for (const entry of entries) {
      const line = node('p', undefined, feed);
      node('strong', `${state.profiles[entry.author].name}：`, line);
      node('span', entry.text, line);
    }
    if (pinned) feed.scrollTop = feed.scrollHeight;
  }
  function render(key) {
    const state = snapshot;
    if (key === 'chat' || key === 'diary') {
      feed = node('div'); feed.className = 'mobile-feed'; feed.setAttribute('role', 'log'); feed.setAttribute('aria-live', 'polite');
      updateFeed(state);
      const input = field(key === 'chat' ? '訊息' : '今天的日記', '', key === 'chat' ? 300 : 800, true);
      const send = async () => { const value = input.value; const result = await request({action: key, text: value}); if (input.value === value) input.value = ''; if (page === key) updateFeed(result); };
      button(key === 'chat' ? '送出' : '記下今天', send);
    } else if (key === 'note') {
      const input = field('留給彼此的話', state.note, 180, true);
      button('貼上便條', async () => { await request({action: 'note', text: input.value, revision: state.revision}); close(); window.homeMobile.toast('便條已同步'); });
      button('重新讀取', () => openPanel('note'));
    } else if (key === 'connect') {
      const input = field('你的暱稱', state.profiles[state.id].name, 12);
      button('保存', async () => { await request({action: 'profile', name: input.value, status: '在家'}); close(); });
    } else if (key === 'shop') {
      node('p', `共同錢包 ${state.coins}`);
      for (const item of state.catalog) {
        const owned = state.owned.includes(item.id);
        const buy = button(`${item.name} · ${owned ? '已擺好' : `${item.price} 金幣`}`, async () => { await request({action: 'purchase', id: item.id}); await openPanel('shop'); });
        buy.disabled = owned || state.coins < item.price;
      }
    } else if (key === 'date') {
      const title = field('約會名稱', state.date?.title || '', 80);
      const link = field('活動網址（可留空）', state.date?.link || '', 2048); link.type = 'url';
      button('保存約會', async () => { await request({action: 'date', title: title.value, link: link.value}); await openPanel('date'); window.homeMobile.toast('約會已保存'); });
      if (state.date?.link && /^https?:\/\//.test(state.date.link)) { const a = node('a', '開啟活動網址'); a.href = state.date.link; a.target = '_blank'; a.rel = 'noopener noreferrer'; }
    } else if (key === 'hug') {
      const invitation = state.invitation;
      if (invitation?.status === 'pending' && Date.now() - invitation.at < 60000) {
        node('p', invitation.author === state.id ? '等待伴侶回覆' : '伴侶想抱抱你');
        if (invitation.author !== state.id) for (const [label, answer] of [['好呀','accepted'],['今天先不要','declined']]) button(label, async () => { await request({action: 'respond', id: invitation.id, answer}); close(); });
      } else button('送出抱抱邀請', async () => { await request({action: 'invite'}); close(); });
      button('更新', () => openPanel('hug'));
    } else if (key === 'cards') {
      const question = state.question;
      if (!question) button('抽一張卡', async () => { await request({action: 'question'}); await openPanel('cards'); });
      else {
        node('p', question.prompt);
        for (const [id, answer] of Object.entries(question.answers)) node('p', `${state.profiles[id].name}：${answer}`);
        if (!Object.hasOwn(question.answers, state.id)) {
          const input = field('你的答案', '', 180, true);
          button('交出答案', async () => { await request({action: 'answer', id: question.id, text: input.value}); await openPanel('cards'); });
        } else if (Object.keys(question.answers).length < 2) node('p', '已交卷，等待伴侶');
        button('更新答案', () => openPanel('cards'));
        if (Object.keys(question.answers).length === 2) button('下一張', async () => { await request({action: 'question'}); await openPanel('cards'); });
      }
    }
  }
  setInterval(async () => {
    if (!entered) return;
    const state = window.homeMobile.state;
    el('mobile-status').textContent = state.status || '正在回家';
    el('mobile-coins').textContent = state.ready ? `${state.coins} 金幣` : '';
    el('mobile-action').textContent = state.action || '互動';
    el('mobile-action').disabled = !state.connected || !state.action || blocked();
    if (pollBusy || document.hidden || !dialog.open || !['chat', 'diary'].includes(page)) return;
    const token = generation; pollBusy = true;
    try { const result = await request(); if (token === generation) updateFeed(result); }
    catch { /* Keep unsent text and the last received messages during reconnect. */ }
    finally { pollBusy = false; }
  }, 400);
})();
