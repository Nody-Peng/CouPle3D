'use strict';
// Event-driven shell details; no extra scene objects or animation loop.
let sprintEnabled=false,quietMotion=false;
try{quietMotion=localStorage.getItem('together-quiet-motion')==='true';}catch{}
document.documentElement.classList.toggle('quiet-motion',quietMotion);
function stopControls(){sprintEnabled=false;resetStick();$('touch-sprint').setAttribute('aria-pressed','false');}
function controlsView(){
 title('散步，也要順手','YOUR LITTLE FIELD GUIDE');
 $('modal-content').innerHTML=`<div class="controls-intro"><span>一起探索心動之城</span><h3>走到喜歡的地方，按 E 開始。</h3><p>靠近入口時，右下角會顯示可以進行的活動。離開操作視窗後可直接繼續移動。</p></div><div class="controls-grid">${[['移動','W A S D ／方向鍵','沿目前視角前後左右移動'],['快走','按住 Shift','步行時加快速度'],['互動','E','靠近光環、入口或服務櫃台'],['腳踏車','B','戶外上車或下車，放開移動鍵減速'],['旋轉視角','Q ／ R','按住向左或向右旋轉'],['縮放','滑鼠滾輪 ／ ＋ −','放大角色或看遠一點'],['回正視角','C','恢復預設方向、縮放並離開全景'],['園區全景','M','切換園區鳥瞰'],['日夜','N','切換白天與夜晚'],['操作說明','H ／ ?','隨時查看這張指南'],['全螢幕','F','再按一次離開，可用 Esc 退出全螢幕'],['關閉視窗','Esc','回到散步；小遊戲進度會保留']].map(([name,key,desc])=>`<article><b>${name}</b><kbd>${key}</kbd><small>${desc}</small></article>`).join('')}</div><div class="notice"><b>手機操作</b><br>拖曳左下搖桿移動，點「快走」切換速度；右下角可互動、轉視角和縮放。橫向畫面較適合探索。</div><label class="motion-option"><input type="checkbox" id="quiet-motion" ${quietMotion?'checked':''}> 減少介面動畫 <small>偏好會記在這台裝置；不改變遊戲規則。</small></label><div class="row"><button id="controls-guide">選個散步目的地</button><button id="controls-recover">卡住了？回安全入口</button><button id="controls-back" class="primary">繼續散步</button></div>`;
 $('quiet-motion').onchange=e=>{quietMotion=e.target.checked;document.documentElement.classList.toggle('quiet-motion',quietMotion);try{localStorage.setItem('together-quiet-motion',String(quietMotion));}catch{}};
 $('controls-guide').onclick=()=>openView('guide');
 $('controls-recover').onclick=async()=>{await closeView();command('recover');command('camera_reset');toast('已回到安全入口，視角也回正了');};
 $('controls-back').onclick=closeView;
}
const controlsRender=render;render=function(){if(view==='controls')return controlsView();controlsRender();};
const controlsOpen=openView;openView=async function(name){stopControls();await controlsOpen(name);};
const controlsInput=window.togetherBridge.input;
window.togetherBridge.input=()=>JSON.stringify({...JSON.parse(controlsInput()),sprint:sprintEnabled&&!view&&!document.hidden});
$('touch-sprint').onclick=()=>{sprintEnabled=!sprintEnabled;$('touch-sprint').setAttribute('aria-pressed',String(sprintEnabled));};
$('cancel-guide').onclick=()=>{guideTarget=null;$('walk-guide').hidden=true;$('cancel-guide').hidden=true;toast('已取消散步指引');focusWorld();};
async function toggleFullscreen(){
 try{if(document.fullscreenElement)await document.exitFullscreen();else if(document.documentElement.requestFullscreen)await document.documentElement.requestFullscreen();else return toast('這個瀏覽器不支援全螢幕，橫向遊玩也很舒服。');focusWorld();}catch{toast('無法切換全螢幕，請使用瀏覽器的全螢幕功能。');}
}
$('fullscreen-toggle').onclick=toggleFullscreen;
document.addEventListener('fullscreenchange',()=>{$('fullscreen-toggle').textContent=document.fullscreenElement?'離開全螢幕 F':'全螢幕 F';});
function shellKeys(e){
 if(!state||e.repeat||e.ctrlKey||e.metaKey||e.altKey||e.isComposing)return;
 if(e.target.closest?.('input,textarea,select,[contenteditable="true"]'))return;
 if(view){if(e.code==='Escape'){e.preventDefault();e.stopImmediatePropagation();closeView();}return;}
 if(e.code==='KeyH'||e.key==='?'){e.preventDefault();openView('controls');}
 else if(e.code==='KeyF'){e.preventDefault();toggleFullscreen();}
 else if(e.code==='KeyC'){e.preventDefault();command('camera_reset');focusWorld();}
}
document.addEventListener('keydown',shellKeys,true);
$('game-frame').addEventListener('load',()=>{
 const doc=$('game-frame').contentDocument;if(!doc)return;
 doc.addEventListener('keydown',shellKeys,true);
 doc.defaultView.addEventListener('blur',stopControls);
});
document.addEventListener('visibilitychange',()=>{stopControls();if(gameLoaded)command('pause',{value:document.hidden||!!view});});
window.addEventListener('blur',stopControls);
const controlsReady=window.togetherBridge.ready;
window.togetherBridge.ready=()=>{controlsReady();command('pause',{value:document.hidden||!!view});toast(matchMedia('(pointer:coarse)').matches?'拖曳左下搖桿散步 · 靠近入口點互動':'WASD 散步 · 靠近入口按 E · 按 H 查看操作');focusWorld();};
let lastTip='',lastRide=null,lastPlace='',previousCoins=null,coinTimer=null;
const controlsPosition=window.togetherBridge.position;
window.togetherBridge.position=raw=>{
 controlsPosition(raw);const p=position;
 const tip=p.activity?`附近有「${p.activity}」 · 按 E 互動`:p.riding?'騎乘中 · B 下車 · 放開方向鍵減速':'WASD 散步 · Shift 快走 · H 操作指南';
 if(lastTip!==tip){$('world-tip').textContent=tip;lastTip=tip;}
 $('interact').disabled=!p.activity;$('interact').classList.toggle('available',!!p.activity);
 $('bicycle-toggle').setAttribute('aria-pressed',String(p.riding));
 document.querySelector('[data-command="map"]').setAttribute('aria-pressed',String(!!p.overview));
 $('night-toggle').setAttribute('aria-pressed',String(!!p.night));$('night-toggle').textContent=p.night?'切換白天 N':'切換夜晚 N';
 $('cancel-guide').hidden=!guideTarget||p.scene!=='park';
 $('touch-sprint').disabled=!!p.riding;
 if(lastRide!==null&&lastRide!==p.riding)toast(p.riding?'上車囉！轉彎時會自動放慢':'已下車，繼續散步吧');lastRide=p.riding;
 const place=$('place').textContent;if(lastPlace&&lastPlace!==place){$('place').classList.remove('place-arrival');void $('place').offsetWidth;$('place').classList.add('place-arrival');}lastPlace=place;
};
const controlsAccept=accept;accept=function(next){
 const old=previousCoins;controlsAccept(next);previousCoins=next.user.coins;
 if(old!==null&&old!==previousCoins){const amount=previousCoins-old,node=$('coin-feedback');node.textContent=`${amount>0?'+':''}${amount} 金幣`;node.className=amount>0?'earned':'spent';node.hidden=false;clearTimeout(coinTimer);coinTimer=setTimeout(()=>{node.hidden=true;},2200);}
};
$('coin-feedback').hidden=true;
