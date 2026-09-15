'use strict';
const foldDefault=[[[20,4],[26,7],[27,13],[23,17],[17,17],[13,13],[14,7],[20,4]],[[20,17],[20,32],[10,46]],[[20,32],[31,46]],[[6,25],[20,22],[34,26]]];
const foldLegacyRules={width:100,height:100,figureRadius:7,inkRadius:3,figureScale:.3,margin:10,maxRounds:30};
let foldDraft=null,foldDraftId='',foldSelected=0,foldPending=false,foldAim=null,foldSeen='',foldAnimation=null,foldTimer=null;
const foldArt=strokes=>strokes.map(line=>`<polyline points="${line.map(p=>p.join(',')).join(' ')}"/>`).join('');
function foldFigure(f,x,color,rules){
 const scale=rules.figureScale;
 return `<g transform="translate(${x-20*scale} ${f.y-25*scale}) scale(${scale})" fill="none" stroke="${f.hit?'#aaa':color}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">${foldArt(f.strokes)}</g>${f.hit?`<text x="${x}" y="${f.y+1}" text-anchor="middle" fill="#a54c75" font-size="${rules.figureRadius*2}">×</text>`:''}`;
}
function foldFormation(rules){
 const points=[],margin=rules.margin+2;
 for(let tries=0;points.length<3&&tries<200;tries++){
  const p={x:margin+Math.random()*(rules.width-2*margin),y:margin+Math.random()*(rules.height-2*margin)};
  if(points.every(q=>Math.hypot(p.x-q.x,p.y-q.y)>=(rules.separation||22)+6))points.push(p);
 }
 return points.length===3?points:[{x:rules.width*.24,y:rules.height*.24},{x:rules.width*.67,y:rules.height*.48},{x:rules.width*.31,y:rules.height*.77}];
}
async function foldAction(action,data={}){
 if(foldPending)return;foldPending=true;
 try{await api(action,data);foldAim=null;}catch(e){toast(e.message);}finally{foldPending=false;if(view==='fold')foldView();}
}
const foldShotLabel=s=>s.hits.length?`命中 ${s.hits.length} 人`:s.near?'擦身而過！':'落空，再抓一下位置';
function foldView(){
 title('對折墨水戰','A LITTLE PAPER RIVALRY');
 const g=state.fold,mine=state.user.id,enemy=mine==='a'?'b':'a';
 if(!g){
  $('modal-content').innerHTML=`<div class="fold-intro"><span class="fold-badge">白紙挑戰 · 同回合對決</span><h3>紙更大，墨更小。<br>默契之外，比一點眼力。</h3><div class="fold-cover"><span>✎</span><i></i><span>✿</span></div><p>畫好三個小人，藏進大張白紙。雙方各自在自己的半張紙選好一滴墨，再一起對折揭曉。</p><p class="small">沒有格線、沒有鏡射準星。墨點碰到小人的固定判定範圍即命中；同回合全滅就平手。最多 30 回合，比誰的眼力更準。</p><button id="fold-start" class="primary">攤開大白紙</button></div>`;
  $('fold-start').onclick=()=>foldAction('fold/new');return;
 }
 const rules=g.rules||foldLegacyRules,w=rules.width,h=rules.height,simultaneous=g.version===2;
 if(foldDraftId!==g.id){
  foldDraftId=g.id;foldDraft=foldFormation(rules).map(f=>({...f,strokes:structuredClone(foldDefault)}));
  foldAim=null;foldSeen=`${g.id}:${g.shots.length}`;foldAnimation=null;clearTimeout(foldTimer);
 }
 const setup=g.status==='setup',ready=!!g.figures[mine],finished=g.status==='finished';
 const waiting=simultaneous&&!!g.ownPending,canAim=!setup&&!finished&&(simultaneous?!waiting:g.turn===mine);
 const own=g.figures[mine]||foldDraft,opponent=g.figures[enemy]||[];
 const latest=g.shots.slice(simultaneous?-2:-1),key=`${g.id}:${g.shots.length}`;
 if(latest.length&&key!==foldSeen){
  foldAnimation={key,until:Date.now()+2700};clearTimeout(foldTimer);
  foldTimer=setTimeout(()=>{if(view==='fold')foldView();},2750);
 }
 foldSeen=key;
 const animating=foldAnimation?.key===key&&Date.now()<foldAnimation.until;
 const round=simultaneous?g.round:Math.min(30,Math.floor(g.shots.length/2)+1);
 const displayRound=animating?latest[0].round||round:round;
 const status=setup?(ready?'你的畫紙已封好，等伴侶準備':'畫好小隊員，再點白紙安排位置'):animating?'兩滴墨，一起揭曉…':finished?(g.winner==='draw'?'平手！你們的眼力不分上下':g.winner===mine?'你贏了！小小墨水神射手':'伴侶獲勝，再比一次眼力吧'):waiting?'這一滴已封好，等伴侶落墨':canAim?'在自己的半張紙選一滴墨':'等待伴侶落墨';
 const fresh=g.shots.length-latest.length;
 // Keep results covered while the two paper folds are being presented.
 const visibleFigure=(f,i,owner)=>animating&&latest.some(s=>s.player!==owner&&s.hits.includes(i))?{...f,hit:false}:f;
 const splats=g.shots.map((s,i)=>{
  const actual=s.player===mine?2*w-s.x:w-s.x;
  return `<g class="fold-splat ${i>=fresh&&animating?'fresh':''}" transform="translate(${actual} ${s.y})"><circle r="${rules.inkRadius}" fill="${s.player===mine?'#d94d80':'#348ca2'}" opacity=".78"/><circle cx="${rules.inkRadius*.28}" cy="${-rules.inkRadius*.25}" r="${rules.inkRadius*.34}" fill="white" opacity=".25"/></g>`;
 }).join('');
 const aim=waiting?g.ownPending:foldAim;
 const selection=(f,i)=>setup&&!ready&&foldSelected===i?`<circle cx="${f.x}" cy="${f.y}" r="${rules.figureRadius+1}" fill="none" stroke="#d783a3" stroke-width=".25"/>`:'';
 const stats=owner=>{const shots=g.shots.filter(s=>s.player===owner);return `${shots.length?Math.round(shots.filter(s=>s.hits.length).length/shots.length*100):0}%`;};
 $('modal-content').innerHTML=`
  ${!simultaneous&&!finished?'<div class="notice">這張是更新前的畫紙，沿用原規則完成。下一局就會使用大白紙與雙方同回合結算。</div>':''}
  <div class="fold-status" role="status"><div><span class="fold-badge">${setup?'DRAW YOUR TINY TEAM':finished&&!animating?'OUR PAPER MEMORY':'SECRET DROPS • FAIR ROUNDS'}</span><h3>${status}</h3></div><b>${displayRound}<small> / ${rules.maxRounds} 回合</small></b></div>
  <div class="fold-score"><span>你的小隊 ${3-own.filter((f,i)=>visibleFigure(f,i,mine).hit).length} / 3</span><small>${setup?'每人三個小人':finished?'本局完成':simultaneous?`你：${waiting?'已封墨':'選點中'} · 伴侶：${g.partnerReady?'已封墨':'選點中'}`:'原版對局'}</small><span>${esc(state.partner.name)}的小隊 ${3-opponent.filter((f,i)=>visibleFigure(f,i,enemy).hit).length} / 3</span></div>
  <div class="fold-table" style="--paper-ratio:${2*w/h}">
   <svg id="fold-paper" viewBox="0 0 ${2*w} ${h}" role="img" aria-label="左邊是你的白紙，右邊是伴侶白紙">
    <rect width="${2*w}" height="${h}" fill="#fff"/>
    ${own.map((f,i)=>selection(f,i)+foldFigure(visibleFigure(f,i,mine),f.x,'#b5446d',rules)).join('')}
    ${opponent.map((f,i)=>foldFigure(visibleFigure(f,i,enemy),w+f.x,'#337b8a',rules)).join('')}
    ${splats}<path d="M${w} 0V${h}" stroke="#e4e4e4" stroke-width=".25"/>
    ${aim&&(canAim||waiting)&&!animating?`<circle class="fold-aim" cx="${aim.x}" cy="${aim.y}" r="${rules.inkRadius}" fill="#d6477b"/>`:''}
   </svg>
   ${animating?`<div class="fold-leaf from-left"></div>${simultaneous?'<div class="fold-leaf from-right"></div>':''}`:''}
  </div>
  <div class="fold-caption"><span>你的半張紙 · ${setup?'部署區':'落墨區'}</span><span>摺痕</span><span>伴侶的半張紙</span></div>
  ${setup&&!ready?`<div class="fold-workshop"><section><h3>畫你的小隊員</h3><div class="fold-pencils">${foldDraft.map((f,i)=>`<button data-figure="${i}" aria-pressed="${i===foldSelected}">小人 ${i+1}</button>`).join('')}</div><svg id="fold-sketch" viewBox="0 0 40 50" aria-label="自由畫小人" fill="none" stroke="#b5446d" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${foldArt(foldDraft[foldSelected].strokes)}</svg><button id="fold-clear">清空重畫</button><button id="fold-template">套用小人</button></section><section><h3>小小的人，大大的紙</h3><p>選一個小人，再點左半張白紙就能移動。小人要分開站，不能貼邊。</p><p class="small">小人與墨點都更小了；自由畫的外觀不影響固定命中範圍。交戰時不顯示判定圈，也沒有格線幫忙對準。</p><button id="fold-scatter">換個陣形</button><button id="fold-ready" class="primary" ${foldPending?'disabled':''}>三人就位，封好畫紙</button></section></div>`:''}
  ${!setup&&!finished?`<div class="fold-actions"><p>${animating?'對折中，稍後開始下一回合。':waiting?'你的落點已鎖定，伴侶看不到位置。雙方準備好後一起結算。':canAim?'估算鏡射位置，點左半張白紙。確認後這一滴就不能更改。':'等伴侶完成落墨。'}</p>${canAim?`<button id="fold-drop" class="primary" ${!foldAim||animating||foldPending?'disabled':''}>${simultaneous?'封好這一滴':'滴墨，對折！'}</button><button id="fold-reset" ${animating?'disabled':''}>重新選點</button>`:''}</div>`:''}
  ${latest.length&&!animating?`<div class="fold-round-report" aria-live="polite"><b>第 ${latest[0].round||Math.ceil(g.shots.length/2)} 回合</b>${latest.map(s=>`<span class="${s.hits.length?'hit':''}">${s.player===mine?'你':esc(state.partner.name)} · ${foldShotLabel(s)}</span>`).join('')}${simultaneous&&latest.every(s=>s.hits.length)?'<em>默契命中！</em>':''}</div>`:''}
  ${finished&&!animating?`<div class="fold-result"><h3>${g.winner==='draw'?'這次一起贏了眼力挑戰':g.winner===mine?'把這張勝利畫紙收藏起來':'下一張白紙，再次挑戰'}</h3><p>${g.reason==='surrender'?'本局提前結束，沒有發放獎勵。':`你的獎勵：${g.winner==='draw'?30:g.winner===mine?40:25} 金幣。${g.reason==='limit'?'30 回合結束，依命中人數結算。':g.winner==='draw'?'同一回合雙方全滅，公平平手！':''}`}</p><p class="small">命中率：你 ${stats(mine)} · ${esc(state.partner.name)} ${stats(enemy)}</p><button id="fold-again" class="primary">再玩一張大白紙</button></div>`:!finished?'<button id="fold-exit" class="quiet">結束本局（不發獎勵）</button>':''}`;
 const paper=$('fold-paper');
 paper.onclick=e=>{
  if(foldPending||animating)return;
  const p=new DOMPoint(e.clientX,e.clientY).matrixTransform(paper.getScreenCTM().inverse());
  if(p.x<rules.inkRadius||p.x>w-rules.inkRadius||p.y<rules.inkRadius||p.y>h-rules.inkRadius)return;
  if(setup&&!ready){foldDraft[foldSelected].x=Math.max(rules.margin,Math.min(w-rules.margin,p.x));foldDraft[foldSelected].y=Math.max(rules.margin,Math.min(h-rules.margin,p.y));foldView();}
  else if(canAim){foldAim={x:p.x,y:p.y};foldView();}
 };
 document.querySelectorAll('[data-figure]').forEach(b=>b.onclick=()=>{foldSelected=Number(b.dataset.figure);foldView();});
 $('fold-clear')?.addEventListener('click',()=>{foldDraft[foldSelected].strokes=[];foldView();});
 $('fold-template')?.addEventListener('click',()=>{foldDraft[foldSelected].strokes=structuredClone(foldDefault);foldView();});
 $('fold-scatter')?.addEventListener('click',()=>{const positions=foldFormation(rules);foldDraft=foldDraft.map((f,i)=>({...f,...positions[i]}));foldView();});
 $('fold-ready')?.addEventListener('click',()=>foldAction('fold/place',{gameId:g.id,figures:foldDraft}));
 $('fold-drop')?.addEventListener('click',()=>{if(foldAim)foldAction('fold/drop',{gameId:g.id,...(simultaneous?{round:g.round}:{shotNumber:g.shots.length}),...foldAim});});
 $('fold-reset')?.addEventListener('click',()=>{foldAim=null;foldView();});
 $('fold-again')?.addEventListener('click',()=>foldAction('fold/new'));
 $('fold-exit')?.addEventListener('click',()=>{if(confirm('結束這張畫紙？雙方這局都不會獲得金幣。'))foldAction('fold/surrender',{gameId:g.id});});
 bindFoldSketch();
}
function bindFoldSketch(){
 const sketch=$('fold-sketch');if(!sketch)return;
 let line=null,element=null;
 const point=e=>{const p=new DOMPoint(e.clientX,e.clientY).matrixTransform(sketch.getScreenCTM().inverse());return [Math.round(Math.max(0,Math.min(40,p.x))*10)/10,Math.round(Math.max(0,Math.min(50,p.y))*10)/10];};
 sketch.onpointerdown=e=>{const strokes=foldDraft[foldSelected].strokes;if(strokes.length>=20||strokes.flat().length>=238)return toast('畫紙筆畫已滿，清空後再試。');sketch.setPointerCapture(e.pointerId);line=[point(e),point(e)];strokes.push(line);element=document.createElementNS('http://www.w3.org/2000/svg','polyline');element.setAttribute('points',line.map(p=>p.join(',')).join(' '));sketch.append(element);};
 sketch.onpointermove=e=>{if(!line||foldDraft[foldSelected].strokes.flat().length>=240)return;const p=point(e),last=line.at(-1);if(Math.hypot(p[0]-last[0],p[1]-last[1])<1)return;line.push(p);element.setAttribute('points',line.map(p=>p.join(',')).join(' '));};
 sketch.onpointerup=sketch.onpointercancel=()=>{line=null;foldView();};
}
const foldRender=render;render=function(){if(view==='fold')return foldView();foldRender();};
