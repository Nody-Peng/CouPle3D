'use strict';
// Persistent menu buttons retain their existing handlers and account state.
const hudRender=render;
render=function(){
 const menu=view==='menu';$('game-menu').hidden=!menu;$('menu-back').hidden=menu;
 if(!menu)return hudRender();
 title('散步小手冊','TOGETHER CITY');
 $('modal-content').innerHTML='<p class="menu-intro">靠近場景裡的入口就能互動。想換裝、玩一局或調整設定，也可以從這裡開始。</p>';
};
$('menu-back').onclick=()=>openView('menu');
$('camera-toggle').onclick=()=>{const open=$('camera-tools').hidden;$('camera-tools').hidden=!open;$('camera-toggle').setAttribute('aria-expanded',String(open));};
const hudOpen=openView;openView=async function(name){$('camera-tools').hidden=true;$('camera-toggle').setAttribute('aria-expanded','false');await hudOpen(name);document.body.classList.add('panel-open');};
const hudClose=closeView;closeView=async function(){await hudClose();document.body.classList.remove('panel-open');};
// Original callbacks held the old function reference; rebind both dismissal paths.
$('close-modal').onclick=()=>closeView();
$('modal').addEventListener('close',()=>document.body.classList.remove('panel-open'));
// Categories remain a single accessible tab order; no duplicate action handlers.
const menuGroups=[['我的生活',['wardrobe','shop','bank','furniture']],['一起玩',['numberhunt','flick','battleship','ink','fold','dessert']],['探索與收藏',['daily','zoo']],['操作與設定',['controls']]];
for(const [label,ids] of menuGroups){
 const section=document.createElement('section');section.className='menu-section';const heading=document.createElement('h3');heading.textContent=label;section.append(heading);
 for(const id of ids){const button=$('game-menu').querySelector(`[data-view="${id}"]`);if(button)section.append(button);}
 $('game-menu').append(section);
}
const settings=$('game-menu').lastElementChild;
for(const element of [...$('game-menu').children])if(element.tagName==='BUTTON')settings.append(element);
const hudPosition=window.togetherBridge.position;
window.togetherBridge.position=raw=>{
 hudPosition(raw);const p=position,coarse=matchMedia('(pointer:coarse)').matches;
 $('interact').textContent=p.activity?(coarse?'互動': 'E · 互動'):(coarse?'探索中':'靠近入口');
 $('interact').setAttribute('aria-label',p.activity?'互動：'+p.activity:'靠近場景入口後互動');
 $('world-tip').textContent=p.activity|| (coarse?'靠近光環，開始互動':'WASD 移動 · E 互動 · Esc 選單');
};
// Scale the thumb displacement to the actual pad size, and release on lost capture.
moveStick=function(e){const r=pad.getBoundingClientRect(),radius=r.width*.32,x=(e.clientX-r.left-r.width/2)/radius,y=(e.clientY-r.top-r.height/2)/radius,len=Math.max(1,Math.hypot(x,y));touch={x:x/len,y:y/len};$('stick').style.transform=`translate(${touch.x*radius*.8}px,${touch.y*radius*.8}px)`;};
pad.addEventListener('lostpointercapture',resetStick);
