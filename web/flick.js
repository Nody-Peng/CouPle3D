'use strict';
let flickPending=false,flickInviteSeen='',flickAnimated='',flickAnimating=false,flickAim=null,flickAnimationToken=0;

async function flickAction(action,data={}){
  if(flickPending||flickAnimating)return;flickPending=true;if(view==='flick')flickView();
  try{await api(action,data);}catch(e){toast(e.message);}
  finally{flickPending=false;if(view==='flick'&&!flickAnimating)flickView();}
}
const flickPlayerName=(id,my)=>id===my?'你':'伴侶';

function flickBoard(g,my,interactive){
  const r=g.rules.puckRadius,goal=g.rules.goal;
  const pucks=g.pucks.map(p=>`<g class="flick-piece owner-${p.owner} ${p.owner===my?'mine':'partner'} ${p.scored?'scored':''}" data-flick-puck="${p.id}" transform="translate(${p.x} ${p.y})"><circle class="flick-hit" r="30"/><circle class="flick-body" r="${r}"/><circle class="flick-rim" r="${r-5}"/><text y="4">${+p.id.slice(1)+1}</text></g>`).join('');
  return `<svg id="flick-board" viewBox="0 0 ${g.rules.width} ${g.rules.height}" role="application" aria-label="圓片彈射遊戲桌"><defs><pattern id="flick-grain" width="36" height="36" patternUnits="userSpaceOnUse"><path d="M0 8h36M0 27h36"/></pattern></defs><rect class="flick-felt" x="8" y="8" width="784" height="464" rx="28"/><rect class="flick-grain" x="18" y="18" width="764" height="444" rx="22"/><line class="flick-midline" x1="400" y1="30" x2="400" y2="450"/><circle class="flick-goal-ring" cx="${goal.x}" cy="${goal.y}" r="${goal.radius}"/><circle class="flick-goal" cx="${goal.x}" cy="${goal.y}" r="${goal.radius-r}"/><text class="flick-goal-text" x="${goal.x}" y="${goal.y+5}" text-anchor="middle">GOAL</text><g id="flick-pieces">${pucks}</g><g id="flick-aim" hidden><line class="flick-pull"/><line class="flick-path"/><circle class="flick-handle" r="9"/></g></svg>`;
}

function flickPoint(svg,event){const point=svg.createSVGPoint();point.x=event.clientX;point.y=event.clientY;return point.matrixTransform(svg.getScreenCTM().inverse());}
function bindFlickControls(g,my){
  const svg=$('flick-board');if(!svg||g.turn!==my||flickPending||flickAnimating)return;
  svg.querySelectorAll('.flick-piece.mine:not(.scored)').forEach(piece=>piece.onpointerdown=event=>{
    event.preventDefault();const puck=g.pucks.find(p=>p.id===piece.dataset.flickPuck),point=flickPoint(svg,event);flickAim={pointer:event.pointerId,puckId:puck.id,start:{x:puck.x,y:puck.y},current:point};svg.setPointerCapture(event.pointerId);drawFlickAim(svg);
  });
  svg.onpointermove=event=>{if(!flickAim||event.pointerId!==flickAim.pointer)return;flickAim.current=flickPoint(svg,event);drawFlickAim(svg);};
  const release=event=>{
    if(!flickAim||event.pointerId!==flickAim.pointer)return;const aim=flickAim;flickAim=null;drawFlickAim(svg);
    const dx=aim.start.x-aim.current.x,dy=aim.start.y-aim.current.y,length=Math.hypot(dx,dy);if(length<12){toast('再往後拉一點，才彈得出去');return;}
    const scale=Math.min(g.rules.maxSpeed/length,.13);flickAction('flick/shoot',{gameId:g.id,puckId:aim.puckId,vx:dx*scale,vy:dy*scale});
  };
  svg.onpointerup=release;svg.onpointercancel=()=>{flickAim=null;drawFlickAim(svg);};
}
function drawFlickAim(svg){
  const aim=$('flick-aim');if(!aim)return;if(!flickAim){aim.hidden=true;return;}aim.hidden=false;
  const {start,current}=flickAim,dx=start.x-current.x,dy=start.y-current.y,length=Math.hypot(dx,dy)||1,preview=Math.min(150,length*1.35),px=start.x+dx/length*preview,py=start.y+dy/length*preview;
  const [pull,path]=aim.querySelectorAll('line');pull.setAttribute('x1',start.x);pull.setAttribute('y1',start.y);pull.setAttribute('x2',current.x);pull.setAttribute('y2',current.y);path.setAttribute('x1',start.x);path.setAttribute('y1',start.y);path.setAttribute('x2',px);path.setAttribute('y2',py);const handle=aim.querySelector('circle');handle.setAttribute('cx',current.x);handle.setAttribute('cy',current.y);
}
function animateFlick(g){
  if(!g.last?.frames?.length||g.last.key===flickAnimated)return;flickAnimated=g.last.key;flickAnimating=true;const token=++flickAnimationToken,svg=$('flick-board');
  const frames=[g.last.from,...g.last.frames],pieces=Object.fromEntries([...svg.querySelectorAll('[data-flick-puck]')].map(p=>[p.dataset.flickPuck,p]));let index=0;
  const step=()=>{
    if(token!==flickAnimationToken||view!=='flick'){flickAnimating=false;return;}const positions=Object.fromEntries(frames[index].map(([id,x,y])=>[id,{x,y}]));
    for(const [id,piece] of Object.entries(pieces)){const p=positions[id];piece.style.display=p?'':'none';if(p)piece.setAttribute('transform',`translate(${p.x} ${p.y})`);}
    index++;if(index<frames.length)setTimeout(step,26);else{flickAnimating=false;if(view==='flick')flickView();}
  };step();
}

function flickView(){
  title('圓片彈射','TABLETOP FLICK');const g=state.flick,my=state.user.id,partner=state.partner.id,content=$('modal-content');
  if(!g){
    content.innerHTML=`<div class="flick-lobby"><div class="flick-poster" aria-hidden="true"><i class="flick-poster-goal">GOAL</i>${Array.from({length:8},(_,i)=>`<b class="a" style="--x:${14+(i%2)*12}%;--y:${18+Math.floor(i/2)*20}%"></b><b class="b" style="--x:${74+(i%2)*12}%;--y:${18+Math.floor(i/2)*20}%"></b>`).join('')}</div><div><span class="flick-eyebrow">桌上玩具 · 輪流彈射</span><h3>拉開、瞄準，<br>把圓片送進中央。</h3><p>雙方各有 8 枚圓片。輪流將自己的圓片往中央彈，也可以利用碰撞改變其他圓片的位置。</p><ol><li>按住自己的圓片，往反方向拖曳</li><li>放開後依拖曳距離決定力道</li><li>先讓 8 枚同色圓片進圈的人獲勝</li></ol><button id="flick-new" class="primary">邀請伴侶開桌</button></div></div>`;$('flick-new').onclick=()=>flickAction('flick/new');return;
  }
  const invitedByMe=g.invitedBy===my;
  if(g.status==='waiting'){
    content.innerHTML=`<div class="flick-wait"><div class="flick-wait-disc"></div><span class="flick-eyebrow">PRIVATE TABLE</span><h3>${invitedByMe?'圓片已經擺好了':'伴侶邀請你玩圓片彈射'}</h3><p>${invitedByMe?'等伴侶入座後，由你先彈第一枚。':'接受後會直接開桌，邀請者先手。'}</p><div>${invitedByMe?'<button id="flick-cancel" class="quiet">收起遊戲</button>':'<button id="flick-decline" class="quiet">這次先不要</button><button id="flick-accept" class="primary">接受並入座</button>'}</div></div>`;
    if($('flick-cancel'))$('flick-cancel').onclick=()=>flickAction('flick/cancel',{gameId:g.id});if($('flick-decline'))$('flick-decline').onclick=()=>flickAction('flick/decline',{gameId:g.id});if($('flick-accept'))$('flick-accept').onclick=()=>flickAction('flick/accept',{gameId:g.id});return;
  }
  if(g.status==='finished'){
    const won=g.winner===my,draw=g.winner==='draw',completed=g.reason==='completed';
    content.innerHTML=`<div class="flick-result"><span class="flick-eyebrow">TABLE CLEARED</span><div class="flick-result-discs"><i></i><i></i><i></i></div><h3>${completed?(draw?'同時清空，平手！':won?'你先收完八枚！':'伴侶先清空圓片'):'這局提前結束'}</h3><p>${completed?`比分 ${g.scores[my]}：${g.scores[partner]}，你獲得 ${g.rewards?.[my]||0} 金幣。`:'提前結束不發放金幣。'}</p><button id="flick-rematch" class="primary">重新擺一桌</button></div>`;$('flick-rematch').onclick=()=>flickAction('flick/new');return;
  }
  const turn=g.turn===my,status=turn?'輪到你：選一枚圓片，往後拉再放開':`等待伴侶彈射第 ${g.shots+1} 次`;
  const dots=id=>Array.from({length:g.rules.goalScore},(_,i)=>`<i class="${i<g.scores[id]?'filled':''}"></i>`).join('');
  content.innerHTML=`<div class="flick-status"><div><span class="flick-eyebrow">${turn?'YOUR TURN':'PARTNER TURN'}</span><strong>${status}</strong></div><span>${g.shots}<small> 次彈射</small></span></div>${!state.partner.online?'<div class="naval-offline">伴侶暫時離線，桌面會原樣保留。</div>':''}<div class="flick-score"><div class="owner-${my}"><b>你</b><span>${dots(my)}</span><strong>${g.scores[my]}</strong></div><div class="owner-${partner}"><b>伴侶</b><span>${dots(partner)}</span><strong>${g.scores[partner]}</strong></div></div><div class="flick-table-wrap">${flickBoard(g,my,turn)}</div><div class="flick-footer"><p>${turn?'拖得越遠，力道越大。虛線是出手方向。':'可以先觀察圓片位置，想想下一球怎麼撞。'}</p><button id="flick-surrender" class="quiet danger">結束這局</button></div>`;
  bindFlickControls(g,my);$('flick-surrender').onclick=()=>{if(confirm('確定結束這局？提前結束不會發放金幣。'))flickAction('flick/surrender',{gameId:g.id});};animateFlick(g);
}

const flickRender=render;render=function(){if(view==='flick')return flickView();flickRender();const button=document.querySelector('[data-view="flick"]');if(button)button.textContent=state?.flick?.status==='waiting'&&state.flick.invitedBy!==state.user.id?'圓片彈射 · 有邀請':'圓片彈射';};
const flickActivity=window.togetherBridge.activity;window.togetherBridge.activity=(id,titleText,description)=>{if(id==='flick')openView('flick');else flickActivity(id,titleText,description);};
const flickAcceptState=accept;accept=function(next){const invitation=next.flick?.status==='waiting'&&next.flick.invitedBy!==next.user.id?next.flick.id:'';flickAcceptState(next);if(invitation&&invitation!==flickInviteSeen){flickInviteSeen=invitation;toast(`${next.partner.name} 邀請你玩圓片彈射`);}};
