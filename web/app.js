'use strict';
const $=id=>document.getElementById(id);
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
let state=null,events=null,view='',connected=false,gameLoaded=false,busy=false,commands=[],lastSignature='',avatarDraft=null,layoutDraft=null,selected='',position=null,posting=false;
let ships=[{x:0,y:0,direction:'h'},{x:0,y:2,direction:'h'},{x:3,y:4,direction:'v'}];
let touch={x:0,y:0};
const command=(type,data={})=>commands.push({type,...data});
const toast=(message)=>{$('toast').textContent=message;$('toast').hidden=false;clearTimeout(toast.timer);toast.timer=setTimeout(()=>$('toast').hidden=true,4500);};
async function api(action,data={}) {
  const res=await fetch('/api/'+action,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)});
  const payload=await res.json();if(!res.ok)throw new Error(payload.error||'操作失敗');if(payload.user)accept(payload);return payload;
}
async function act(action,data,success) {
  if(busy)return;busy=true;
  try{await api(action,data);if(success)toast(success);}catch(e){toast(e.message);}finally{busy=false;}
}
function accept(next) {
  state=next;connected=true;$('connection').hidden=true;
  $('identity').textContent=state.user.name;$('coins').textContent=state.user.coins;
  $('partner-status').textContent=state.partner.name+(state.partner.online?' · 在線':' · 暫時離線');
  command('state',{user_id:state.user.id,avatar:avatarDraft||state.user.avatar,partner:state.partner,layout:layoutDraft||state.home.layout,inventory:state.homeInventory,archived:state.home.archived});
  const signature=JSON.stringify([state.user,state.home.bank,state.home.archived,state.home.revision,state.home.lock?.user,state.game,state.ink,state.quiz,state.task,state.partner.online]);
  if(view&&signature!==lastSignature)render();lastSignature=signature;
}
function connectEvents() {
  events?.close();events=new EventSource('/api/events');
  events.onmessage=e=>accept(JSON.parse(e.data));
  events.onerror=()=>{connected=false;$('connection').hidden=false;};
}
function enter(next) {
  accept(next);$('welcome').hidden=true;$('app').hidden=false;connectEvents();
  if(!gameLoaded){$('game-frame').src='/game/index.html';gameLoaded=true;}
}
$('login-form').addEventListener('submit',async e=>{
  e.preventDefault();const id=e.submitter?.value;if(!id)return;
  $('login-error').textContent='';e.submitter.disabled=true;
  try{enter(await api('login',{id,code:$('code').value}));}catch(error){$('login-error').textContent=error.message;}finally{e.submitter.disabled=false;}
});
$('logout').onclick=async()=>{await closeView();events?.close();await api('logout');location.reload();};
document.querySelectorAll('[data-view]').forEach(b=>b.onclick=()=>openView(b.dataset.view));
document.querySelectorAll('[data-command]').forEach(b=>b.onclick=()=>command(b.dataset.command));
$('close-modal').onclick=closeView;$('modal').addEventListener('cancel',e=>{e.preventDefault();closeView();});
async function closeView() {
  if(view==='furniture'&&layoutDraft){try{await api('layout/cancel');}catch{}layoutDraft=null;}
  if(view==='wardrobe'&&state)command('avatar',{avatar:state.user.avatar});
  $('modal').close();view='';avatarDraft=null;command('wardrobe',{value:false});command('pause',{value:false});touch={x:0,y:0};
  if(state)command('state',{user_id:state.user.id,avatar:state.user.avatar,partner:state.partner,layout:state.home.layout,inventory:state.homeInventory,archived:state.home.archived});
}
async function openView(name) {
  if(!state)return;if(view)await closeView();view=name;$('modal').className=name;
  if(name==='wardrobe'){avatarDraft=structuredClone(state.user.avatar);command('wardrobe',{value:true});}
  command('pause',{value:true});render();$('modal').showModal();
}
function title(text,kicker='OUR LITTLE WORLD'){$('modal-title').textContent=text;$('modal-kicker').textContent=kicker;}
function render(){if(!state)return;({wardrobe:wardrobeView,shop:shopView,bank:bankView,furniture:furnitureView,battleship:gameView,daily:dailyView,info:infoView}[view]||infoView)();}
function owned(item){return state.user.inventory.some(x=>x.item===item);}
const icon=item=>({hat:'⌒',glasses:'◎',bag:'▣',furniture:'▤'}[item.type]||'◇');
function wardrobeView() {
  title('今天想穿什麼？','YOUR WARDROBE');
  const labels={'female-a':'女生 · 日常','female-b':'女生 · 休閒','male-a':'男生 · 日常','male-b':'男生 · 休閒'};
  const a=avatarDraft||state.user.avatar;
  $('modal-content').innerHTML=`<p class="small">選擇後，世界中的角色會立即預覽。儲存後伴侶也會看見新造型。</p><div class="avatar-options">${state.bases.filter(base=>lookFilter==="all"||base.startsWith(lookFilter)).map(base=>`<button data-base="${base}" aria-pressed="${a.base===base}">${labels[base]||((base.startsWith("female")?"女生":"男生")+" · 造型 "+(base.charCodeAt(base.length-1)-96))}</button>`).join('')}</div><div class="row">${['outfit','hat','glasses','bag'].map((slot,i)=>`<label>${['服裝','髮飾與帽子','眼鏡','包包'][i]}<select data-slot="${slot}"><option value="none">不配戴</option>${state.catalog.filter(x=>x.type===slot&&owned(x.id)).map(x=>`<option value="${x.id}" ${a[slot]===x.id?'selected':''}>${x.name}</option>`).join('')}</select></label>`).join('')}</div><div class="notice">服裝與髮飾可在商店收藏；奶油針織背心可免費領取。所有基本造型皆可自由使用。</div><div class="row"><button class="primary" id="save-avatar">保存造型</button><button id="to-shop">去看看配件</button></div>`;
  $('modal-content').querySelectorAll('[data-base]').forEach(b=>b.onclick=()=>{avatarDraft.base=b.dataset.base;command('avatar',{avatar:avatarDraft});wardrobeView();});
  $('modal-content').querySelectorAll('[data-slot]').forEach(s=>s.onchange=()=>{avatarDraft[s.dataset.slot]=s.value;command('avatar',{avatar:avatarDraft});});
  $('save-avatar').onclick=()=>act('avatar',{avatar:avatarDraft},'新造型已保存');$('to-shop').onclick=()=>openView('shop');
}
function shopView() {
  title('帶一點喜歡的回家','THE LITTLE SHOP');
  $('modal-content').innerHTML=`<div class="row space"><span>個人 <b>${state.user.coins}</b> 金幣 · 共同 <b>${state.home.bank}</b> 金幣</span><label>付款錢包 <select id="wallet"><option value="personal">個人錢包</option><option value="shared" ${state.home.archived?'disabled':''}>共同銀行（家具）</option></select></label></div><div class="grid">${state.catalog.map(item=>`<article class="item"><div class="swatch" style="--color:${item.color}">${icon(item)}</div><strong>${item.name}</strong><p>${esc(item.description||'可以擺放在家中的綠色布置區。')}</p><span class="price">${item.price} 金幣</span><button data-buy="${item.id}" ${item.type!=='furniture'&&owned(item.id)?'disabled':''}>${item.type!=='furniture'&&owned(item.id)?'已擁有':'購買'}</button></article>`).join('')}</div>`;
  $('modal-content').querySelectorAll('[data-buy]').forEach(b=>b.onclick=async()=>{
    const wallet=$('wallet').value,item=b.dataset.buy;
    if(wallet==='shared'&&state.catalog.find(i=>i.id===item).type!=='furniture')return toast('共同銀行只用來購買家具');
    b.disabled=true;await act('purchase',{item,wallet,requestId:crypto.randomUUID()},'已加入收藏');if(b.isConnected)b.disabled=false;
  });
}
function bankView() {
  title('一起存一個小夢想','OUR SHARED BANK');
  $('modal-content').innerHTML=`<div class="wallet-total">${state.home.bank} <small>共同金幣</small></div><p>你的錢包還有 ${state.user.coins} 金幣。</p><div class="notice">金幣存入後不能領回個人錢包。兩人都能用共同金幣買家具，每筆交易都會留下紀錄。</div>${state.home.archived?'<div class="notice warning">共同住宅與銀行已封存。個人物品仍保留。</div>':'<form id="deposit-form" class="row"><input id="deposit-amount" type="number" min="1" step="1" value="30" aria-label="存入金額" required><button class="primary">存入共同銀行</button></form>'}<h3>共同紀錄</h3><div class="ledger">${state.home.ledger.length?state.home.ledger.map(e=>`<div class="ledger-row"><span>${e.user===state.user.id?'你':state.partner.name} · ${esc(e.text)}<br><small>${new Date(e.at).toLocaleString('zh-TW')}</small></span><b>${e.amount>0?'+':''}${e.amount||''}</b></div>`).join(''):'<p class="small">還沒有交易，從第一筆存款開始吧。</p>'}</div>${state.home.archived?'':'<details><summary>配對與共同資產</summary><p>封存會停止共同銀行與住宅編輯，保留共同物品；不會分配或複製共同資產。個人物品仍歸原主人。本雛形尚未提供新配對介面。</p><button id="archive-home" class="danger">封存共同住宅</button></details>'}`;
  $('deposit-form')?.addEventListener('submit',e=>{e.preventDefault();act('bank/deposit',{amount:Number($('deposit-amount').value)},'已存入共同銀行');});
  if($('archive-home'))$('archive-home').onclick=()=>{if(confirm('確定封存共同住宅與銀行？這個雛形沒有自助解除封存功能。'))act('home/archive',{confirm:'ARCHIVE'},'共同資產已封存，個人物品仍保留');};
}
function furnitureItems(){return state.homeInventory.filter((item,index,arr)=>state.catalog.find(c=>c.id===item.item)?.type==='furniture'&&arr.findIndex(x=>x.instance===item.instance)===index);}
function furnitureView() {
  title('把家布置成我們的樣子','HOME STUDIO');
  if(state.home.archived){$('modal-content').innerHTML='<div class="notice warning">共同住宅已封存，無法編輯。</div>';return;}
  if(layoutDraft&&state.home.lock?.user!==state.user.id){layoutDraft=null;toast('編輯鎖已到期，未保存的修改已取消');}
  if(!layoutDraft){$('modal-content').innerHTML=`<p>移動、旋轉或收回已購買的家具。綠色區域可自由布置，通道與原有家具會保留。</p><div class="notice">兩人都可以布置，同一時間由一人編輯。未保存的修改不會影響伴侶。</div><div class="row"><button id="start-edit" class="primary" ${state.home.lock&&state.home.lock.user!==state.user.id?'disabled':''}>${state.home.lock&&state.home.lock.user!==state.user.id?'伴侶正在布置':'開始布置'}</button><button id="undo-layout">恢復上一版</button></div><p class="small">已保存 ${state.home.layout.length} 件家具 · 配置版本 ${state.home.revision}</p>`;
    $('start-edit').onclick=async()=>{try{await api('layout/lock');layoutDraft=structuredClone(state.home.layout);selected='';command('home');render();}catch(e){toast(e.message);}};
    $('undo-layout').onclick=async()=>{try{await api('layout/lock');await api('layout/undo',{revision:state.home.revision});toast('已恢復上一版');}catch(e){toast(e.message);}};return;
  }
  const items=furnitureItems(),layout=layoutDraft;
  $('modal-content').innerHTML=`<div class="notice">先選家具，再點綠色區域擺放。位置會吸附到半格；保存時檢查碰撞。世界裡同步顯示你的預覽。</div><div class="editor-columns"><svg id="edit-map" class="edit-map" viewBox="-21 -18 42 36" role="img" aria-label="住宅家具布置圖"><path d="M-7 -18V18M7 -18V18M-21 0H21" stroke="#b5a78e" stroke-width=".2"/>${[['廚房',-15,-10],['臥室',-1,-10],['浴室',13,-10],['客廳',-15,6],['遊戲室',-2,6],['書房',13,6]].map(([n,x,z])=>`<text x="${x}" y="${z}">${n}</text>`).join('')}${state.zones.map(z=>`<rect class="zone" x="${z.x}" y="${z.z}" width="${z.width}" height="${z.depth}"/>`).join('')}${layout.map(p=>{const instance=items.find(i=>i.instance===p.instance),c=state.catalog.find(c=>c.id===instance?.item)||{width:1,depth:1,color:'#999'};return `<rect data-instance="${p.instance}" class="placed ${selected===p.instance?'selected':''}" x="${p.x-c.width/2}" y="${p.z-c.depth/2}" width="${c.width}" height="${c.depth}" fill="${c.color}" transform="rotate(${p.rotation} ${p.x} ${p.z})"/>`;}).join('')}</svg><div><h3>你的家具與共同家具</h3><div class="inventory-list">${items.length?items.map(i=>`<button data-select="${i.instance}" ${selected===i.instance?'class="primary"':''}>${state.catalog.find(c=>c.id===i.item).name} · ${i.owner==='shared'?'共同':'個人'} ${layout.some(p=>p.instance===i.instance)?'／已擺放':''}</button>`).join(''):'<p class="small">先到小商店買一件家具吧。</p>'}</div><div class="row"><button id="rotate-item">旋轉 90°</button><button id="remove-item">收回</button></div><p class="small">${selected?'已選擇家具，點擊綠色區域。':'點選一件家具開始。'}</p></div></div><div class="row"><button id="save-layout" class="primary">保存布置</button><button id="cancel-layout">取消修改</button></div>`;
  const preview=()=>command('layout',{layout:layoutDraft,inventory:items});
  $('modal-content').querySelectorAll('[data-select],[data-instance]').forEach(b=>b.onclick=e=>{e.stopPropagation();selected=b.dataset.select||b.dataset.instance;render();});
  $('edit-map').onclick=e=>{if(!selected)return toast('先選擇一件家具');const svg=$('edit-map'),point=new DOMPoint(e.clientX,e.clientY).matrixTransform(svg.getScreenCTM().inverse());let p=layoutDraft.find(p=>p.instance===selected);if(!p){p={instance:selected,x:0,z:0,rotation:0};layoutDraft.push(p);}p.x=Math.round(point.x*2)/2;p.z=Math.round(point.y*2)/2;preview();render();};
  $('rotate-item').onclick=()=>{const p=layoutDraft.find(p=>p.instance===selected);if(p){p.rotation=(p.rotation+90)%360;preview();render();}};
  $('remove-item').onclick=()=>{layoutDraft=layoutDraft.filter(p=>p.instance!==selected);preview();render();};
  $('save-layout').onclick=async()=>{try{await api('layout/save',{layout:layoutDraft,revision:state.home.revision});layoutDraft=null;toast('布置已保存');render();}catch(e){toast(e.message);}};
  $('cancel-layout').onclick=async()=>{await api('layout/cancel');layoutDraft=null;command('layout',{layout:state.home.layout,inventory:items});render();};
}
function dailyView() {
  title('花園需要一點照顧','A SMALL DAILY RITUAL');const count=state.user.daily.day===state.today?state.user.daily.count:0;
  $('modal-content').innerHTML=`<p>沿著園區南側步道，替三座花圃澆水。每次完整完成獲得 <b>25 金幣</b>，每天最多三次。</p><div class="notice">今天完成 ${count} / 3 次。日界線採台灣時間。關閉視窗後，用地面的金色標記找到委託花圃。</div>${state.garden.map((p,i)=>`<div class="step ${state.task&&i<state.task.step?'done':''}"><span class="step-number">${i+1}</span><span>南側花圃 ${i+1}<br><small>${state.task?.step===i?'目前目標 · 靠近並停留 3 秒後按 E 澆水':state.task&&i<state.task.step?'已完成':'等待澆水'}</small></span></div>`).join('')}<div class="row"><button id="start-task" class="primary" ${count>=3?'disabled':''}>${state.task?'重新接取':'接取委託'}</button>${state.task?'<button id="water-task">澆水</button>':''}</div>`;
  $('start-task').onclick=async()=>{await act('task/start',{},'已接取委託，請前往南側花圃');if(state.task){command('task',{step:state.task.step});await closeView();}};
  if($('water-task'))$('water-task').onclick=()=>act('task/water',{},'花圃已澆水');
}
let info={title:'約會入口',description:'這個活動會在之後的版本加入。'};
function infoView(){title(info.title);$('modal-content').innerHTML=`<p>${esc(info.description)}</p><div class="notice">第一版先提供海戰棋、墨水大戰、花園委託、換裝與家庭布置。</div><button id="info-game" class="primary">去海戰俱樂部</button>`;$('info-game').onclick=()=>openView('battleship');}

// Only same-origin Godot iframe uses this bridge; state is still validated by the backend.
window.togetherBridge={
  ready(){ $('loading').hidden=true;command('state',{user_id:state.user.id,avatar:state.user.avatar,partner:state.partner,layout:state.home.layout,inventory:state.homeInventory,archived:state.home.archived});command('pause',{value:!!view}); },
  commands(){const result=JSON.stringify(commands);commands=[];return result;},
  input(){return JSON.stringify(view?{x:0,y:0}:touch);},
  position(raw){position=JSON.parse(raw);$('place').textContent=position.scene==='home'?'我們的家':'園區散步';},
  activity(id,title,description){if(id==='battleship'||id==='tabletop')openView('battleship');else if(id.startsWith('garden_')){if(state.task)act('task/water',{},'澆水完成');else openView('daily');}else if(id==='memories'||id==='studio'){openView('furniture');}else{info={title,description};openView('info');}},
  error(message){toast(message);},
};
setInterval(async()=>{if(!state||!position||posting||document.hidden)return;posting=true;try{await api('position',position);}catch(e){if(!/速度/.test(e.message)){connected=false;$('connection').hidden=false;}}finally{posting=false;}},400);
setInterval(()=>{if(layoutDraft&&connected)api('layout/heartbeat').catch(e=>{layoutDraft=null;render();toast(e.message);});},25000);
const pad=$('touch-pad');let pointer=null;
function moveStick(e){const r=pad.getBoundingClientRect(),x=(e.clientX-r.left-r.width/2)/35,y=(e.clientY-r.top-r.height/2)/35,len=Math.max(1,Math.hypot(x,y));touch={x:x/len,y:y/len};$('stick').style.transform=`translate(${touch.x*28}px,${touch.y*28}px)`;}
pad.onpointerdown=e=>{pointer=e.pointerId;pad.setPointerCapture(pointer);moveStick(e);};pad.onpointermove=e=>{if(e.pointerId===pointer)moveStick(e);};
function resetStick(){pointer=null;touch={x:0,y:0};$('stick').style.transform='';}pad.onpointerup=resetStick;pad.onpointercancel=resetStick;window.addEventListener('blur',resetStick);document.addEventListener('visibilitychange',resetStick);
fetch('/api/session').then(async r=>{if(r.ok){const data=await r.json();if(data.user)enter(data);}}).catch(()=>{});



// District activities and richer account screens extend the existing game shell.
let shopFilter='all',shopWallet='personal';
const productArt=item=>item.type==='furniture'?`<div class="product-art furniture-art ${item.id}" style="--color:${item.color}"><i></i><i></i><i></i></div>`:`<div class="product-art"><img src="/previews/${item.id}.png" alt="${esc(item.name)}穿戴效果"></div>`;
const originalWardrobeView=wardrobeView;
wardrobeView=function(){
  originalWardrobeView();
  const content=$('modal-content');
  content.querySelectorAll('[data-base]').forEach(b=>{const label=b.textContent;b.innerHTML=`<img src="/previews/${b.dataset.base}.png" alt=""><span>${label}</span>`;});
  content.insertAdjacentHTML('afterbegin',`<form id="profile-form" class="profile-row"><label>角色暱稱<input id="profile-name" maxlength="12" value="${esc(state.user.name)}" required></label><button>更新暱稱</button></form>`);
  $('profile-form').onsubmit=e=>{e.preventDefault();act('profile',{name:$('profile-name').value},'暱稱已更新');};
  content.insertAdjacentHTML('beforeend','<div class="row preview-controls"><button id="turn-avatar-left">向左轉</button><button id="turn-avatar-right">向右轉</button><span class="small">旋轉查看背包與完整穿搭</span></div>');
  $('turn-avatar-left').onclick=()=>command('preview_turn',{angle:-0.5});$('turn-avatar-right').onclick=()=>command('preview_turn',{angle:0.5});
};
shopView=function(){
  title('帶一點喜歡的回家','CITY DEPARTMENT STORE');
  const items=state.catalog.filter(i=>shopFilter==='all'||(shopFilter==='accessories'?i.type!=='furniture':i.type==='furniture'));
  $('modal-content').innerHTML=`<div class="shop-banner"><div><span class="eyebrow">收藏日常的小美好</span><h3>今天的心動選物</h3><p>配件陪你散步，家具留住兩個人的日常。</p></div><div class="shop-balance"><small>我的金幣</small><b>${state.user.coins.toLocaleString()}</b></div></div><div class="row space"><div class="filter-tabs">${[['all','全部選物'],['accessories','服裝與配件'],['furniture','家庭家具']].map(([id,label])=>`<button data-filter="${id}" aria-pressed="${shopFilter===id}">${label}</button>`).join('')}</div><label>付款錢包 <select id="wallet"><option value="personal">個人錢包</option><option value="shared" ${state.home.archived?'disabled':''}>共同銀行（${state.home.bank} 幣）</option></select></label></div><div class="grid">${items.map(item=>{const has=item.type!=='furniture'&&owned(item.id),funds=shopWallet==='shared'?state.home.bank:state.user.coins,unavailable=shopWallet==='shared'&&item.type!=='furniture';return `<article class="item">${productArt(item)}<span class="product-category">${item.type==='furniture'?'HOME COLLECTION':'DAILY ACCESSORIES'}</span><strong>${item.name}</strong><p>${esc(item.description||'為家裡留一個舒服的小角落。')}</p><div class="product-buy"><span class="price">${item.price} <small>金幣</small></span><button data-buy="${item.id}" ${has||funds<item.price||unavailable?'disabled':''}>${has?'已收藏':unavailable?'限個人購買':funds<item.price?'金幣不足':'加入收藏'}</button></div></article>`;}).join('')}</div>`;
  $('wallet').value=shopWallet;$('wallet').onchange=()=>{shopWallet=$('wallet').value;shopView();};
  document.querySelectorAll('[data-filter]').forEach(b=>b.onclick=()=>{shopFilter=b.dataset.filter;shopView();});
  document.querySelectorAll('[data-buy]').forEach(b=>b.onclick=()=>act('purchase',{item:b.dataset.buy,wallet:shopWallet,requestId:crypto.randomUUID()},'已加入收藏'));
};
function walletView(){
  title('每一點努力，都留在這裡','MY WALLET');
  const ledger=state.user.ledger||[],earned=ledger.filter(x=>x.amount>0).reduce((n,x)=>n+x.amount,0);
  $('modal-content').innerHTML=`<div class="wallet-hero"><span>可使用金幣</span><strong>${state.user.coins.toLocaleString()}</strong><small>一起玩、慢慢存，讓日常更可愛。</small></div><div class="wallet-stats"><div><small>近期獲得</small><b>+${earned}</b></div><div><small>共同銀行</small><b>${state.home.bank}</b></div><div><small>我的收藏</small><b>${state.user.inventory.filter(i=>i.owner===state.user.id).length}</b></div></div><div class="row"><button id="earn-garden">花園委託 · 25 幣</button><button id="earn-zoo">動物手帳 · 30 幣</button><button id="earn-game">海戰棋 · 35–45 幣</button></div><h3>金幣明細</h3><div class="ledger">${ledger.length?ledger.map(e=>`<div class="ledger-row"><span>${esc(e.text)}<br><small>${new Date(e.at).toLocaleString('zh-TW')} · 餘額 ${e.balance}</small></span><b class="${e.amount>0?'income':''}">${e.amount>0?'+':''}${e.amount}</b></div>`).join(''):'<p class="small">初始體驗金已在錢包裡。接下來的收入與支出都會記錄在這裡。</p>'}</div>`;
  $('earn-garden').onclick=()=>openView('daily');$('earn-zoo').onclick=()=>openView('zoo');$('earn-game').onclick=()=>openView('battleship');
}
function zooView(){
  title('心森愛心動物觀察手帳','SIX HABITATS · A HEART-SHAPED WALK');
  const stamps=state.user.zoo?.day===state.today?state.user.zoo.stamps:[],habitats=state.zooHabitats||[];
  $('modal-content').innerHTML=`<div class="zoo-intro"><span class="eyebrow">慢慢散步，認識每一位新朋友</span><h3>今天和誰打招呼了？</h3><p>沿著愛心環道，拜訪六種動物。每天任選三個觀察點收集印章，<br>自動獲得 <b>30 金幣</b>；其餘棲地也可以繼續收藏。</p><progress value="${Math.min(stamps.length,3)}" max="3"></progress><span>${stamps.length} / ${habitats.length} 棲地已拜訪 · ${stamps.length>=3?'今日獎勵已領取':'還差 '+(3-stamps.length)+' 枚可領獎勵'}</span></div><div class="stamp-grid">${habitats.map(h=>`<article class="stamp ${stamps.includes(h.id)?'collected':''}"><img class="animal-portrait" src="/previews/animal-${h.id}.png" alt="${esc(h.name)}"><div class="stamp-seal">${stamps.includes(h.id)?'已觀察':'待發現'}</div><h3>${h.name}</h3><p>${h.description}</p><button data-stamp="${h.id}" ${stamps.includes(h.id)?'disabled':''}>收集印章</button><button class="quiet" data-guide-x="${h.entryX}" data-guide-z="${h.entryZ}">指引到這裡</button></article>`).join('')}</div>`;
  document.querySelectorAll('[data-stamp]').forEach(b=>b.onclick=()=>act('zoo/stamp',{animal:b.dataset.stamp},'觀察印章已收集'));bindGuides();
}
let guideTarget=null;
function bindGuides(){document.querySelectorAll('[data-guide-x]').forEach(b=>b.onclick=async()=>{guideTarget={x:Number(b.dataset.guideX),z:Number(b.dataset.guideZ)};await closeView();toast('跟著下方距離指引散步，抵達光環後按 E');});}
function guideView(){
  title('今天想往哪裡散步？','THREE DISTRICTS · ONE LITTLE WORLD');
  $('modal-content').innerHTML=`<div class="district-guide">${[['花漾都市','百貨・共同銀行・生活選物',-100,5],['心動樂園','遊樂設施・花園・我們的家',0,29],['心森愛心動物園','六種動物・愛心環道・觀察手帳',100,5]].map(([name,desc,x,z],i)=>`<button class="district-card district-${i}" data-guide-x="${x}" data-guide-z="${z}"><span>0${i+1}</span><h3>${name}</h3><p>${desc}</p><strong>開始散步 →</strong></button>`).join('')}</div><p class="small">三區由中央大道相連。此指引顯示方向與距離，角色仍由你控制移動。</p><button id="recover-player">卡住了？回到安全入口</button>`;
  bindGuides();$('recover-player').onclick=async()=>{await closeView();command('recover');toast('已返回目前場景的安全入口');};
}
const originalRender=render;
render=function(){if(view==='wallet')return walletView();if(view==='zoo')return zooView();if(view==='guide')return guideView();originalRender();};
const oldActivity=window.togetherBridge.activity;
window.togetherBridge.activity=(id,title,description)=>{if(id.startsWith('zoo_')||id==='guide_zoo')openView('zoo');else if(id==='city_shop')openView('shop');else if(id==='city_bank')openView('bank');else if(id==='city_home')openView('furniture');else if(id==='city_cafe'){info={title:'花園咖啡 · 今日的聊天題',description:'如果明天可以一起去任何地方，你會選哪裡？\n輪流分享答案，再繼續今天的散步。'};openView('info');}else oldActivity(id,title,description);};
const oldPosition=window.togetherBridge.position;
window.togetherBridge.position=raw=>{oldPosition(raw);const p=JSON.parse(raw);$('bicycle-toggle').disabled=p.scene==='home';$('bicycle-toggle').textContent=p.riding?'下車 B':'騎腳踏車 B';$('place').textContent=p.scene==='home'?'我們的家':p.x>56?'心森愛心動物園':p.x < -56?'花漾都市':'心動樂園';$('interact').textContent=p.activity?'E · '+p.activity:'互動 E';const g=$('walk-guide');if(guideTarget&&p.scene==='park'){const dx=guideTarget.x-p.x,dz=guideTarget.z-p.z,d=Math.hypot(dx,dz);g.hidden=false;g.textContent=d<3?'已抵達目的地':`散步指引 · ${Math.round(d)} m · ${Math.abs(dx)>Math.abs(dz)?dx>0?'往東 →':'往西 ←':dz>0?'往南 ↓':'往北 ↑'}`;}else g.hidden=true;};

function quizView(){
  title('我們的默契，是哪一種？','THREE LITTLE QUESTIONS');
  const q=state.quiz;
  if(!q){$('modal-content').innerHTML='<div class="zoo-intro"><h3>三個選擇，聊聊彼此。</h3><p>各自回答相同的問題，兩人都交卷後才會揭曉。沒有標準答案，也不影響金幣。</p><button class="primary" id="quiz-start">開始默契問答</button></div>';$('quiz-start').onclick=()=>act('quiz/new',{});return;}
  if(q.results){const matched=q.results.a.filter((x,i)=>x===q.results.b[i]).length;$('modal-content').innerHTML=`<div class="wallet-hero"><span>這次的心意交集</span><strong>${matched} / 3</strong><small>不同的選擇，也值得好好聊聊。</small></div>${state.quizQuestions.map((question,i)=>`<div class="step"><div><h3>${esc(question.title)}</h3><p>你：${question.options[q.results[state.user.id][i]]}<br>${esc(state.partner.name)}：${question.options[q.results[state.partner.id][i]]}</p></div></div>`).join('')}<button id="quiz-start" class="primary">再玩一次</button>`;$('quiz-start').onclick=()=>act('quiz/new',{});return;}
  if(q.answers){$('modal-content').innerHTML='<div class="notice">你的答案已保存。等伴侶完成後，一起揭曉！重新整理也能接續。</div>';return;}
  $('modal-content').innerHTML=`<form id="quiz-form">${state.quizQuestions.map((q,i)=>`<fieldset class="quiz-question"><legend>${i+1}. ${esc(q.title)}</legend>${q.options.map((o,j)=>`<label><input type="radio" name="answer-${i}" value="${j}" required> ${o}</label>`).join('')}</fieldset>`).join('')}<button class="primary">保存我的答案</button></form>`;
  $('quiz-form').onsubmit=e=>{e.preventDefault();const form=new FormData(e.currentTarget);act('quiz/answer',{quizId:q.id,answers:state.quizQuestions.map((_,i)=>Number(form.get('answer-'+i)))},'答案已保存');};
}
const districtRender=render;render=function(){if(view==='quiz')return quizView();districtRender();};
const districtActivity=window.togetherBridge.activity;
window.togetherBridge.activity=(id,title,description)=>{if(id==='trivia')openView('quiz');else districtActivity(id,title,description);};



let lookFilter='all';
const detailedWardrobeView=wardrobeView;
wardrobeView=function(){
 detailedWardrobeView();
 const options=document.querySelector('.avatar-options');
 options.insertAdjacentHTML('beforebegin',`<div class="row space"><span class="small">12 款基本造型，自由搭配已收藏的配件</span><div class="filter-tabs">${[['all','全部'],['female','女生'],['male','男生']].map(([id,label])=>`<button data-look-filter="${id}" aria-pressed="${lookFilter===id}">${label}</button>`).join('')}</div></div>`);
 document.querySelectorAll('[data-look-filter]').forEach(b=>b.onclick=()=>{lookFilter=b.dataset.lookFilter;wardrobeView();});
};

const cafePosition=window.togetherBridge.position;
window.togetherBridge.position=raw=>{cafePosition(raw);const p=JSON.parse(raw);if(p.scene==='park'&&Math.abs(p.x+76)<12&&Math.abs(p.z-25)<10)$('place').textContent='花園咖啡';};

const venueActivity=window.togetherBridge.activity;
window.togetherBridge.activity=(id,title,description)=>{if(id==='bank_atm')openView('wallet');else if(id==='city_fitting')openView('wardrobe');else if(id==='city_furniture'){shopFilter='furniture';openView('shop');}else venueActivity(id,title,description);};

const cityPlace=window.togetherBridge.position;
window.togetherBridge.position=raw=>{cityPlace(raw);const p=JSON.parse(raw);if(p.scene!=='park')return;for(const [name,x,z] of [['一起銀行',-126,-22],['花漾百貨',-76,-22],['生活選物',-126,25]])if(Math.abs(p.x-x)<12&&Math.abs(p.z-z)<10)$('place').textContent=name;};
