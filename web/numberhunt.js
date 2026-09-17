'use strict';
let numberPending=false,numberInviteSeen='';

async function numberAction(action,data={}){
  if(numberPending)return;
  numberPending=true;if(view==='numberhunt')numberHuntView();
  try{await api(action,data);}catch(e){toast(e.message);}
  finally{
    numberPending=false;
    if(view==='numberhunt')numberHuntView();
    if(action==='number/pick')setTimeout(()=>{if(view==='numberhunt')numberHuntView();},520);
  }
}

function numberHuntView(){
  title('找數字競速','FIND IT FIRST');
  const g=state.numberHunt,my=state.user.id,partner=state.partner.id,content=$('modal-content');
  if(!g){
    content.innerHTML=`<div class="number-lobby"><div class="number-sample" aria-hidden="true">${[17,4,31,9,26,12,45,2,38,21,7,42].map((n,i)=>`<i style="--r:${i%2?'-5deg':'4deg'}">${n}</i>`).join('')}</div><div><span class="number-eyebrow">雙人眼力賽 · 五分制</span><h3>同一張數字紙，<br>看誰先找到。</h3><p>每回合會出現一個目標數字。兩人同時在亂序數字中尋找，先點到的人得一分，率先拿到 5 分獲勝。</p><ul class="number-rules"><li>點錯會暫停 0.5 秒</li><li>每題都會重新排列</li><li>勝方 30、另一方 25 金幣</li></ul><button id="number-new" class="primary" ${numberPending?'disabled':''}>邀請伴侶開始</button></div></div>`;
    $('number-new').onclick=()=>numberAction('number/new');return;
  }
  const invitedByMe=g.invitedBy===my;
  if(g.status==='waiting'){
    content.innerHTML=`<div class="number-wait"><span class="number-eyebrow">PRIVATE GAME INVITATION</span><div class="number-target-preview">?</div><h3>${invitedByMe?'邀請已送出':'伴侶邀請你比眼力'}</h3><p>${invitedByMe?'等伴侶接受後，你們會同時看到第一題。':'一局大約兩分鐘，先找到五次目標數字的人獲勝。'}</p><div class="number-wait-actions">${invitedByMe?'<button id="number-cancel" class="quiet">取消邀請</button>':'<button id="number-decline" class="quiet">這次先不要</button><button id="number-accept" class="primary">接受並開始</button>'}</div></div>`;
    if($('number-cancel'))$('number-cancel').onclick=()=>numberAction('number/cancel',{gameId:g.id});
    if($('number-decline'))$('number-decline').onclick=()=>numberAction('number/decline',{gameId:g.id});
    if($('number-accept'))$('number-accept').onclick=()=>numberAction('number/accept',{gameId:g.id});
    return;
  }
  if(g.status==='finished'){
    const completed=g.reason==='completed',won=g.winner===my;
    const reason={declined:'這次邀請沒有開始。',cancelled:'邀請已取消。',surrender:'這局提前結束，雙方不發獎勵。'}[g.reason]||'';
    content.innerHTML=`<div class="number-result"><span class="number-eyebrow">ROUND COMPLETE</span><div class="number-result-mark">${completed?(won?'1':'2'):'−'}</div><h3>${completed?(won?'你先找到五次！':'伴侶先拿到五分'):'遊戲已結束'}</h3><div class="number-final-score"><b>${g.scores[my]}</b><span>比</span><b>${g.scores[partner]}</b></div><p>${completed?`你獲得 ${g.rewards?.[my]||0} 金幣，伴侶獲得 ${g.rewards?.[partner]||0} 金幣。`:reason}</p><button id="number-rematch" class="primary">再邀請一局</button></div>`;
    $('number-rematch').onclick=()=>numberAction('number/new');return;
  }
  const locked=Date.now()<g.lockedUntil;
  const last=g.last,feedback=last?(last.correct?`${last.player===my?'你':'伴侶'}先找到 ${last.value}`:`${last.player===my?'你':'伴侶'}點了 ${last.value}，再找一下`):'第一眼會騙人，慢一點反而更快。';
  const cells=g.board.map((n,i)=>`<button class="number-cell" data-number="${n}" style="--tilt:${(i*17%9)-4}deg;--delay:${i%8}" ${numberPending||locked?'disabled':''} aria-label="數字 ${n}">${n}</button>`).join('');
  content.innerHTML=`<div class="number-score"><div><small>你</small><b>${g.scores[my]}</b></div><span>第 ${g.round} 題 · 先到 ${g.goal} 分</span><div><small>伴侶</small><b>${g.scores[partner]}</b></div></div>${!state.partner.online?'<div class="naval-offline">伴侶暫時離線，題目和分數都會保留。</div>':''}<section class="number-stage"><div class="number-prompt"><small>請找出</small><strong>${g.target}</strong><p class="${last&&!last.correct?'wrong':''}" role="status">${locked?'點錯了，停半秒再找':feedback}</p></div><div class="number-grid">${cells}</div></section><div class="number-footer"><span>兩邊看到的是同一張數字紙</span><button id="number-surrender" class="quiet danger">結束這局</button></div>`;
  content.querySelectorAll('[data-number]:not(:disabled)').forEach(button=>button.onclick=()=>numberAction('number/pick',{gameId:g.id,round:g.round,value:+button.dataset.number}));
  $('number-surrender').onclick=()=>{if(confirm('確定結束這局？提前結束不會發放金幣。'))numberAction('number/surrender',{gameId:g.id});};
}

const numberRender=render;
render=function(){
  if(view==='numberhunt')return numberHuntView();
  numberRender();
  const button=document.querySelector('[data-view="numberhunt"]');
  if(button)button.textContent=state?.numberHunt?.status==='waiting'&&state.numberHunt.invitedBy!==state.user.id?'找數字 · 有邀請':'找數字';
};
const numberActivity=window.togetherBridge.activity;
window.togetherBridge.activity=(id,titleText,description)=>{if(id==='numberhunt')openView('numberhunt');else numberActivity(id,titleText,description);};
const numberAcceptState=accept;
accept=function(next){
  const invitation=next.numberHunt?.status==='waiting'&&next.numberHunt.invitedBy!==next.user.id?next.numberHunt.id:'';
  numberAcceptState(next);
  if(invitation&&invitation!==numberInviteSeen){numberInviteSeen=invitation;toast(`${next.partner.name} 邀請你玩找數字`);}
};
