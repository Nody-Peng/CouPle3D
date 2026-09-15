'use strict';
let inkBrush='dot', inkPending=false, inkSeen='', inkLastMove=0;
const inkBrushes=[
  {id:'dot',name:'細筆',desc:'塗一格，可以補空白或搶回顏色。'},
  {id:'splash',name:'濺墨',desc:'一次性十字筆刷，適合搶中央。'},
  {id:'heart',name:'心形',desc:'一次性斜角筆刷，適合做漂亮包圍。'},
];
const inkName=id=>inkBrushes.find(b=>b.id===id)?.name||'細筆';
const inkCoord=c=>String.fromCharCode(65+c%7)+(Math.floor(c/7)+1);
const inkCells=(cell,brush)=>{const x=cell%7,y=Math.floor(cell/7),shape=brush==='splash'?[[0,0],[1,0],[-1,0],[0,1],[0,-1]]:brush==='heart'?[[0,0],[-1,-1],[1,-1],[-1,1],[1,1]]:[[0,0]];return shape.map(([dx,dy])=>({x:x+dx,y:y+dy})).filter(p=>p.x>=0&&p.x<7&&p.y>=0&&p.y<7).map(p=>p.y*7+p.x);};
async function inkAction(action,data={}){if(inkPending)return;inkPending=true;inkView();try{await api(action,data);}catch(e){toast(e.message);}finally{inkPending=false;if(view==='ink')inkView();}}
function inkView(){
  title('墨水大戰','INK DUEL STUDIO');
  const g=state.ink,my=state.user.id,partner=state.partner.id,content=$('modal-content');
  if(!g){content.innerHTML=`<div class="ink-lobby"><div class="ink-poster" aria-hidden="true"><span class="ink-blob a"></span><span class="ink-blob b"></span><span class="ink-blob c"></span><div class="ink-board-mini">${Array.from({length:49},(_,i)=>`<i style="--d:${i%9}"></i>`).join('')}</div></div><div><span class="ink-eyebrow">七乘七畫布，一局剛剛好</span><h3>把畫布染成<br>你們的顏色。</h3><p>輪流選格上色，特殊筆刷一局只能各用一次。28 手後結算，佔色最多的人獲勝；平手也有小獎勵。</p><ol class="ink-rules"><li>細筆塗一格，穩定擴張</li><li>濺墨塗十字五格，適合反攻</li><li>心形筆刷塗斜角五格，適合包圍</li></ol><button id="new-ink" class="primary" ${inkPending?'disabled':''}>${inkPending?'正在開畫布…':'建立墨水大戰 →'}</button><p class="small">完賽：勝方 42、另一方 30 金幣；平手雙方 32 金幣。投降不發獎勵。</p></div></div>`;$('new-ink').onclick=()=>inkAction('ink/new');return;}
  if(inkBrush!=='dot'&&g.used?.[inkBrush])inkBrush='dot';
  if(inkSeen!==g.id){inkSeen=g.id;inkLastMove=g.moves;}
  const fresh=g.moves>inkLastMove?g.last:null;inkLastMove=g.moves;
  const mine=g.counts[my],theirs=g.counts[partner],total=Math.max(1,mine+theirs),turn=g.turn===my,finished=g.status==='finished';
  const winnerText=g.winner==='draw'?'平手！畫布變成雙色紀念品。':g.winner===my?'你贏了，這張畫布很有你的氣勢。':'伴侶贏了，下一局可以把中央搶回來。';
  const headline=finished?winnerText:turn?'輪到你，選筆刷再點一格':'等伴侶落筆，看看下一片顏色會往哪裡走';
  const preview=turn&&!finished?inkCells(-1,inkBrush):[];
  const board=Array.from({length:49},(_,cell)=>{const owner=g.board[cell],will=turn&&!finished&&inkCells(cell,inkBrush).includes(cell),freshCell=g.last?.cells?.includes(cell);const cls=['ink-cell',owner?`owned-${owner}`:'',freshCell?'fresh':'',will?'brush-preview':''].filter(Boolean).join(' ');return `<button class="${cls}" ${turn&&!finished&&!inkPending?'':'disabled'} data-ink-cell="${cell}" aria-label="${inkCoord(cell)} ${owner==='a'?'小晴顏色':owner==='b'?'阿澄顏色':'空白'}"><span>${inkCoord(cell)}</span>${owner?'<i></i>':''}${freshCell?'<b></b>':''}</button>`;}).join('');
  const brushBar=inkBrushes.map(b=>{const used=b.id!=='dot'&&g.used[b.id];return `<button data-ink-brush="${b.id}" aria-pressed="${inkBrush===b.id}" ${used||inkPending?'disabled':''}><strong>${b.name}</strong><small>${used?'已使用':b.desc}</small></button>`;}).join('');
  const last=g.last?`${g.last.player===my?'你':'伴侶'}用${inkName(g.last.brush)}塗了 ${inkCoord(g.last.cell)}，取得 ${g.last.gained} 格`: '畫布還沒開始沾上顏色';
  content.innerHTML=`<div class="ink-status ${turn&&!finished?'your-turn':''} ${finished?'ink-finished':''}" role="status"><span class="status-beacon"></span><div><strong>${headline}</strong><small>${finished?(g.reason==='surrender'?'這局已結束，可以重新開一張畫布。':`金幣已入帳 · ${my==='a'?state.user.name:state.partner.name} ${g.counts.a} 格 / ${my==='b'?state.user.name:state.partner.name} ${g.counts.b} 格`):'你可以搶空白格，也可以用顏色覆蓋對方的格子。'}</small></div><span class="ink-turns">${g.moves}<small>/ 28 手</small></span></div>${!state.partner.online?'<div class="naval-offline">伴侶暫時離線，畫布會保留，回來後可繼續。</div>':''}<div class="ink-score"><span style="width:${mine/total*100}%"></span><b>${mine}</b><em>${theirs}</em></div><div class="ink-layout"><section class="ink-canvas"><div class="ink-grid">${board}</div></section><aside class="ink-tools"><h3>筆刷盤</h3><div class="ink-brushes">${brushBar}</div><div class="ink-log"><small>最近一筆</small><b>${last}</b></div><div class="ink-tip"><span>策略感</span><p>先用細筆鋪路，等對方佔中央後用濺墨或心形筆刷翻盤。特殊筆刷會覆蓋已上色區域，留到關鍵時刻更痛快。</p></div></aside></div><div class="naval-footer"><span><span class="ink-key mine"></span> 你　<span class="ink-key partner"></span> 伴侶　<span class="ink-key empty"></span> 空白</span>${finished?'<button id="new-ink" class="primary">再畫一局 →</button>':'<button id="ink-surrender" class="quiet danger">結束這局</button>'}</div>${fresh?`<div class="ink-announcement" role="status">${inkName(fresh.brush)}${fresh.gained>=4?'大翻盤':'落筆'}<small>${fresh.player===my?'你':'伴侶'} · +${fresh.gained} 格</small></div>`:''}`;
  content.querySelectorAll('[data-ink-brush]').forEach(b=>b.onclick=()=>{inkBrush=b.dataset.inkBrush;inkView();});
  content.querySelectorAll('[data-ink-cell]:not(:disabled)').forEach(b=>b.onclick=()=>inkAction('ink/paint',{gameId:g.id,cell:+b.dataset.inkCell,brush:inkBrush}));
  if($('new-ink'))$('new-ink').onclick=()=>inkAction('ink/new');
  if($('ink-surrender'))$('ink-surrender').onclick=()=>{if(confirm('結束本局會視為投降，雙方都不會獲得金幣。確定結束？'))inkAction('ink/surrender',{gameId:g.id});};
}
const inkRender=render;render=function(){if(view==='ink')return inkView();inkRender();};
const inkActivity=window.togetherBridge.activity;
window.togetherBridge.activity=(id,title,description)=>{if(id==='ink')openView('ink');else inkActivity(id,title,description);};
