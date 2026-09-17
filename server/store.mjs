import {foldCommand, foldSnapshot} from './fold.mjs';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { CATALOG, CATALOG_MAP, BASES, ZONES, GARDEN, QUIZ, ZOO } from './catalog.mjs';

export class GameError extends Error {
  constructor(message, status=400) { super(message); this.status=status; }
}
const need = (ok, message, status) => { if (!ok) throw new GameError(message,status); };
const integer = (v,min,max) => Number.isInteger(v) && v>=min && v<=max;
export const other = id => id==='a' ? 'b' : 'a';
const day = ms => new Date(ms+8*3600000).toISOString().slice(0,10);
const BANK_APPROVAL_THRESHOLD=80,GIFT_DAILY_LIMIT=50,GOAL_CATEGORIES=['furniture','house','date','collection','other'];

const DESSERT_CARDS={
  whisk:{id:'whisk',name:'雲朵攪拌',type:'cook',tags:['prep','cream'],quality:9,personal:4,harmony:2,icon:'🥣',description:'打出綿密奶油，穩穩提高甜點品質。'},
  bake:{id:'bake',name:'暖爐烘烤',type:'cook',tags:['heat','cake'],quality:11,personal:3,harmony:1,icon:'🔥',description:'掌握火候，讓蛋糕香氣上升。'},
  decorate:{id:'decorate',name:'糖霜裝飾',type:'cook',tags:['finish','cute'],quality:8,personal:5,harmony:3,icon:'🍓',description:'補上草莓、糖霜與愛心擺盤。'},
  teamwork:{id:'teamwork',name:'默契分工',type:'support',tags:['sync','prep','finish'],quality:6,personal:2,harmony:13,icon:'🤝',description:'幫對方接手，適合接任何料理動作。'},
  prank:{id:'prank',name:'麵粉惡作劇',type:'prank',tags:['chaos'],quality:-5,personal:12,harmony:-2,icon:'💨',description:'成功會拿高分，但會讓廚房變混亂。'},
  guard:{id:'guard',name:'圍裙防守',type:'guard',tags:['safe','sync'],quality:3,personal:3,harmony:5,icon:'🛡️',description:'擋下惡作劇，還能漂亮反制。'},
  rescue:{id:'rescue',name:'補救秘方',type:'support',tags:['safe','cream'],quality:7,personal:2,harmony:7,icon:'✨',description:'修復失誤，降低混亂並增加默契。'}
};
const DESSERT_ORDERS=[
  {name:'草莓雲朵鬆餅',hint:'先把奶油打蓬鬆',tags:['prep','cream']},
  {name:'暖心焦糖布丁',hint:'火候剛剛好最重要',tags:['heat']},
  {name:'愛心莓果蛋糕',hint:'漂亮裝飾會大加分',tags:['finish','cute']},
  {name:'雙人午後套餐',hint:'默契分工能做得更快',tags:['sync']},
  {name:'抹茶小山塔',hint:'補救秘方能穩住口感',tags:['safe','cream']},
  {name:'星星奶油派',hint:'烘烤後接裝飾最亮眼',tags:['heat','finish']},
  {name:'粉紅紀念日蛋糕',hint:'可愛擺盤和合作都很重要',tags:['cute','sync']},
  {name:'心動招牌甜點',hint:'把品質、默契和小搗蛋平衡好',tags:['prep','heat','finish','sync']}
];
const clamp=(v,min,max)=>Math.max(min,Math.min(max,v));
const numberBoard=()=>{
  const board=Array.from({length:48},(_,i)=>i+1);
  for(let i=board.length-1;i>0;i--){const j=crypto.randomInt(i+1);[board[i],board[j]]=[board[j],board[i]];}
  return board;
};
const nextNumberRound=g=>{
  g.board=numberBoard();g.target=g.board[crypto.randomInt(g.board.length)];g.lockUntil={a:0,b:0};
};
const FLICK_RULES={width:800,height:480,puckRadius:16,goal:{x:400,y:240,radius:72},maxSpeed:24,goalScore:8};
const flickPucks=()=>{
  const pucks=[];
  for(const owner of ['a','b'])for(let i=0;i<8;i++)pucks.push({id:owner+i,owner,x:(owner==='a'?92:708)+(i%2)*42,y:114+Math.floor(i/2)*84,scored:false});
  return pucks;
};
const simulateFlick=(pucks,launched,vx,vy)=>{
  const r=FLICK_RULES.puckRadius,w=FLICK_RULES.width,h=FLICK_RULES.height,vel=Object.fromEntries(pucks.filter(p=>!p.scored).map(p=>[p.id,{x:0,y:0}]));
  vel[launched.id]={x:vx,y:vy};const frames=[],scored=[];
  for(let step=0;step<260;step++){
    let moving=false;
    for(const puck of pucks){
      if(puck.scored)continue;const v=vel[puck.id];puck.x+=v.x;puck.y+=v.y;
      if(puck.x<r){puck.x=r;v.x=Math.abs(v.x)*.84;}else if(puck.x>w-r){puck.x=w-r;v.x=-Math.abs(v.x)*.84;}
      if(puck.y<r){puck.y=r;v.y=Math.abs(v.y)*.84;}else if(puck.y>h-r){puck.y=h-r;v.y=-Math.abs(v.y)*.84;}
    }
    const active=pucks.filter(p=>!p.scored);
    for(let i=0;i<active.length;i++)for(let j=i+1;j<active.length;j++){
      const a=active[i],b=active[j],dx=b.x-a.x,dy=b.y-a.y,dist=Math.hypot(dx,dy)||.001,min=r*2;
      if(dist>=min)continue;const nx=dx/dist,ny=dy/dist,overlap=(min-dist)/2;a.x-=nx*overlap;a.y-=ny*overlap;b.x+=nx*overlap;b.y+=ny*overlap;
      const va=vel[a.id],vb=vel[b.id],relative=(va.x-vb.x)*nx+(va.y-vb.y)*ny;
      if(relative>0){const impulse=relative*.94;va.x-=impulse*nx;va.y-=impulse*ny;vb.x+=impulse*nx;vb.y+=impulse*ny;}
    }
    for(const puck of pucks){
      if(puck.scored)continue;const v=vel[puck.id],inside=Math.hypot(puck.x-FLICK_RULES.goal.x,puck.y-FLICK_RULES.goal.y)<=FLICK_RULES.goal.radius-r;
      if(inside){puck.scored=true;v.x=0;v.y=0;scored.push(puck.id);continue;}
      v.x*=.976;v.y*=.976;if(Math.hypot(v.x,v.y)<.075){v.x=0;v.y=0;}else moving=true;
    }
    if(step%4===0)frames.push(pucks.filter(p=>!p.scored).map(p=>[p.id,+p.x.toFixed(2),+p.y.toFixed(2)]));
    if(!moving)break;
  }
  for(const puck of pucks){puck.x=+puck.x.toFixed(2);puck.y=+puck.y.toFixed(2);}
  return {frames:frames.slice(0,66),scored};
};
const inkCells = (cell, brush) => {
  const x=cell%7,y=Math.floor(cell/7),shape=brush==='splash'?[[0,0],[1,0],[-1,0],[0,1],[0,-1]]:brush==='heart'?[[0,0],[-1,-1],[1,-1],[-1,1],[1,1]]:[[0,0]];
  return shape.map(([dx,dy])=>({x:x+dx,y:y+dy})).filter(p=>p.x>=0&&p.x<7&&p.y>=0&&p.y<7).map(p=>p.y*7+p.x);
};
export function initialState() {
  const user = (name,base) => ({name,coins:120,avatar:{base,hat:'none',glasses:'none',bag:'none'},inventory:[],daily:{day:'',count:0},receipts:[]});
  return {version:1,users:{a:user('小晴','female-a'),b:user('阿澄','male-a')},home:{bank:0,archived:false,layout:[],previous:[],revision:0,ledger:[],goals:[],proposals:[],bankStats:{totalDeposited:0,goalsCompleted:0}},game:null,ink:null,dessert:null,numberHunt:null,flick:null};
}
export class Store {
  constructor(file, options={}) {
    this.file=file; this.now=options.now || Date.now; this.state=fs.existsSync(file) ? JSON.parse(fs.readFileSync(file,'utf8')) : initialState();
    need(this.state.version===1,'不支援的存檔版本',500);
    this.state.ink ??= null;
    this.state.dessert ??= null;
    this.state.numberHunt ??= null;
    this.state.flick ??= null;
    this.normalizeBank();
    this.presence={}; this.tasks={}; this.editLock=null;
    if(!fs.existsSync(file)) this.persist();
  }
  persist() {
    fs.mkdirSync(path.dirname(this.file),{recursive:true});
    const tmp=this.file+'.tmp';
    const fd=fs.openSync(tmp,'w');
    try { fs.writeFileSync(fd,JSON.stringify(this.state,null,2)); fs.fsyncSync(fd); } finally { fs.closeSync(fd); }
    fs.renameSync(tmp,this.file);
  }
  transaction(fn, label='遊戲獎勵') {
    const old=structuredClone(this.state);
    try { const result=fn(); for(const id of ['a','b']) {const u=this.state.users[id],amount=u.coins-old.users[id].coins;if(amount){u.ledger||=[];u.ledger.unshift({id:crypto.randomUUID(),at:this.now(),text:label,amount,balance:u.coins});u.ledger=u.ledger.slice(0,100);}} this.persist(); return result; } catch(e) {this.state=old;throw e;}
  }
  activeHome() { need(!this.state.home.archived,'共同住宅已封存，個人物品仍保留'); }
  normalizeBank() {
    const h=this.state.home;h.goals ??=[];h.proposals ??=[];h.ledger ??=[];
    if(!h.bankStats){const restoredDeposits=h.ledger.filter(e=>e.amount>0&&((e.type==='deposit')||String(e.text||'').includes('存入'))).reduce((n,e)=>n+e.amount,0);h.bankStats={totalDeposited:restoredDeposits,goalsCompleted:h.goals.filter(g=>g.status==='completed').length};}
    h.bankStats.totalDeposited ??=0;h.bankStats.goalsCompleted ??=0;
    for(const id of ['a','b']){const u=this.state.users[id];u.gifts ??={day:'',sent:0};u.ledger ??=[];}
  }
  log(id,text,amount=0,type='general',meta={}) {
    this.state.home.ledger.unshift({id:crypto.randomUUID(),at:this.now(),user:id,text,amount,type,meta});
    this.state.home.ledger=this.state.home.ledger.slice(0,140);
  }
  bankSnapshot(id) {
    const h=this.state.home,stats=h.bankStats||{},completed=stats.goalsCompleted||0,total=stats.totalDeposited||0;
    const score=total+completed*180,level=Math.max(1,Math.min(12,Math.floor(score/220)+1)),next=level>=12?score:(level*220);
    const gift=this.state.users[id].gifts?.day===day(this.now())?this.state.users[id].gifts.sent:0;
    return {goals:h.goals||[],proposals:h.proposals||[],stats:{totalDeposited:total,goalsCompleted:completed,score,level,next},gift:{sentToday:gift,limit:GIFT_DAILY_LIMIT},threshold:BANK_APPROVAL_THRESHOLD,categories:GOAL_CATEGORIES};
  }
  owns(id,item) {return this.state.users[id].inventory.some(x=>x.item===item);}
  liveLock() { if(this.editLock && this.editLock.expires<=this.now()) this.editLock=null;return this.editLock; }
  position(id,data) {
    const {x,z,scene}=data;
    need(Number.isFinite(x)&&Number.isFinite(z)&&['park','home'].includes(scene),'位置格式錯誤');
    need(Math.abs(x)<=(scene==='home'?21:152)&&(scene==='home'?Math.abs(z)<=18:z>=-44&&z<=56&&(z<=44||Math.abs(x)<=16)),'位置超出地圖');
    const previous=this.presence[id];
    if(previous && previous.scene===scene && this.now()-previous.at<1500) {
      const max=12*(this.now()-previous.at)/1000+2;
      need(Math.hypot(x-previous.x,z-previous.z)<=max,'移動速度過快');
    }
    const garden=scene==='park'?GARDEN.findIndex(t=>Math.hypot(t.x-x,t.z-z)<3):-1;
    this.presence[id]={x,z,scene,riding:scene==='park'&&data.riding===true,yaw:Number.isFinite(data.yaw)?data.yaw:0,at:this.now(),garden,gardenSince:previous?.garden===garden?previous.gardenSince:this.now()};
  }
  snapshot(id) {
    const state=this.state, partner=other(id),g=state.game;
    let game=null;
    if(g) {
      const theirShots=g.shots[partner],mine=g.shots[id];
      const fleet=board=>board?.length===7?[board.slice(0,3),board.slice(3,5),board.slice(5,7)]:[];
      const shots=(cells,board)=>cells.map((cell,index)=>{const ship=fleet(board).find(s=>s.includes(cell));return {cell,hit:!!ship,sunk:!!ship&&ship.every(c=>cells.slice(0,index+1).includes(c))};});
      game={id:g.id,status:g.status,turn:g.turn,winner:g.winner,reason:g.reason,ready:{a:!!g.boards.a,b:!!g.boards.b},
        ownBoard:g.boards[id]||[],ownFleet:fleet(g.boards[id]),enemySunk:fleet(g.boards[partner]).filter(s=>s.every(c=>mine.includes(c))),ownShots:shots(mine,g.boards[partner]),
        incoming:shots(theirShots,g.boards[id]),
        enemyBoard:g.status==='finished'?g.boards[partner]:undefined};
    }
    const p=this.presence[partner];
    return {user:{id,...state.users[id]},partner:{id:partner,name:state.users[partner].name,avatar:state.users[partner].avatar,
      online:!!p&&this.now()-p.at<10000,position:p||null},
      home:{...state.home,lock:this.liveLock()},catalog:CATALOG,bases:BASES,zones:ZONES,garden:GARDEN,zooHabitats:ZOO,
      sharedInventory:state.home.archived?[]:Object.values(state.users).flatMap(u=>u.inventory).filter(x=>x.owner==='shared'),
      homeInventory:Object.values(state.users).flatMap(u=>u.inventory).filter(x=>x.owner===id||x.owner==='shared'||state.home.layout.some(p=>p.instance===x.instance)),
      quiz:state.quiz?{id:state.quiz.id,answers:state.quiz.answers[id],partnerReady:!!state.quiz.answers[partner],results:state.quiz.answers.a&&state.quiz.answers.b?state.quiz.answers:null}:null,quizQuestions:QUIZ,
      game,fold:foldSnapshot(this.state.fold,id),ink:this.inkSnapshot(id),dessert:this.dessertSnapshot(id),numberHunt:this.numberHuntSnapshot(id),flick:this.flickSnapshot(id),bank:this.bankSnapshot(id),task:this.tasks[id]||null,today:day(this.now())};
  }
  inkSnapshot(id) {
    const g=this.state.ink;if(!g)return null;
    const counts={a:g.board.filter(x=>x==='a').length,b:g.board.filter(x=>x==='b').length,empty:g.board.filter(x=>!x).length};
    return {id:g.id,status:g.status,turn:g.turn,winner:g.winner,reason:g.reason,board:g.board,last:g.last,moves:g.moves.length,counts,
      used:g.used[id]||{splash:false,heart:false},partnerUsed:g.used[other(id)]||{splash:false,heart:false}};
  }
  dessertSnapshot(id) {
    const g=this.state.dessert;if(!g)return null;
    const current=g.orders[Math.min(g.round-1,g.orders.length-1)]||g.orders.at(-1);
    return {id:g.id,status:g.status,round:g.round,maxRounds:g.maxRounds,winner:g.winner,reason:g.reason,quality:g.quality,harmony:g.harmony,chaos:g.chaos,scores:g.scores,
      current,orders:g.orders,log:g.log.slice(-8),memory:g.memory||null,rewards:g.rewards||null,cards:Object.values(DESSERT_CARDS),ownAction:g.actions[id],partnerReady:!!g.actions[other(id)]};
  }
  numberHuntSnapshot(id) {
    const g=this.state.numberHunt;if(!g)return null;
    return {id:g.id,status:g.status,invitedBy:g.invitedBy,round:g.round,target:g.target,board:g.board,scores:g.scores,winner:g.winner,reason:g.reason,last:g.last,
      history:(g.history||[]).slice(-8),lockedUntil:g.lockUntil?.[id]||0,goal:g.goal||5,rewards:g.rewards||null};
  }
  flickSnapshot(id) {
    const g=this.state.flick;if(!g)return null;
    return {id:g.id,status:g.status,invitedBy:g.invitedBy,turn:g.turn,pucks:g.pucks,scores:g.scores,winner:g.winner,reason:g.reason,shots:g.shots,last:g.last,rules:FLICK_RULES,rewards:g.rewards||null};
  }
  resolveDessert(g) {
    const a=DESSERT_CARDS[g.actions.a],b=DESSERT_CARDS[g.actions.b];need(a&&b,'甜點行動格式錯誤');
    const round=g.round,order=g.orders[round-1],score={a:a.personal,b:b.personal},delta={quality:a.quality+b.quality,harmony:a.harmony+b.harmony,chaos:0},events=[];
    const match=(card)=>card.tags.some(t=>order.tags.includes(t));
    for(const [pid,card] of [['a',a],['b',b]])if(match(card)){score[pid]+=4;delta.quality+=5;events.push(this.state.users[pid].name+' 抓到食譜提示：'+order.hint);}
    if(a.type==='prank'&&b.type==='guard'){score.a=1;score.b+=9;delta.quality+=5;delta.harmony+=4;events.push(this.state.users.b.name+' 用圍裙接住麵粉，反制成功！');}
    else if(b.type==='prank'&&a.type==='guard'){score.b=1;score.a+=9;delta.quality+=5;delta.harmony+=4;events.push(this.state.users.a.name+' 漂亮防守，廚房沒有爆炸。');}
    else if(a.type==='prank'&&b.type==='prank'){score.a+=2;score.b+=2;delta.quality-=10;delta.chaos+=14;events.push('兩人同時惡作劇，麵粉雲像煙火一樣炸開。');}
    else if(a.type==='prank'||b.type==='prank'){const p=a.type==='prank'?'a':'b',q=other(p);score[q]=Math.max(0,score[q]-2);delta.quality-=4;delta.chaos+=7;events.push(this.state.users[p].name+' 的小搗蛋成功，'+this.state.users[q].name+' 沾到一點奶油。');}
    if(a.type==='cook'&&b.type==='cook'){delta.quality+=7;delta.harmony+=4;events.push('雙料理連擊，香氣直接飄滿廚房。');}
    if((a.type==='support'&&b.type==='cook')||(b.type==='support'&&a.type==='cook')){delta.quality+=6;delta.harmony+=10;events.push('一人料理、一人支援，默契像翻食譜一樣順。');}
    if(a.id==='rescue'||b.id==='rescue'){delta.chaos-=6;events.push('補救秘方把失誤變成可愛亮點。');}
    if(a.id==='bake'&&b.id==='bake'){delta.quality-=6;delta.chaos+=5;events.push('兩人都顧烤箱，邊緣有一點點焦香。');}
    g.scores.a+=Math.max(0,score.a);g.scores.b+=Math.max(0,score.b);g.quality=clamp(g.quality+delta.quality,0,100);g.harmony=clamp(g.harmony+delta.harmony,0,100);g.chaos=clamp(g.chaos+delta.chaos,0,60);
    g.log.push({round,order:order.name,actions:{a:a.id,b:b.id},score,quality:g.quality,harmony:g.harmony,chaos:g.chaos,events:events.slice(0,3)});g.actions={a:null,b:null};
    if(round>=g.maxRounds){const finalA=g.scores.a+Math.round(g.quality*.45)+Math.round(g.harmony*.35)-Math.round(g.chaos*.25),finalB=g.scores.b+Math.round(g.quality*.45)+Math.round(g.harmony*.35)-Math.round(g.chaos*.25);g.status='finished';g.reason='completed';g.winner=finalA===finalB?'draw':(finalA>finalB?'a':'b');
      const grade=g.quality>=86?'S':g.quality>=72?'A':g.quality>=55?'B':'C',shared=clamp(Math.floor((g.quality+g.harmony-g.chaos)/8),6,24),baseA=24+Math.floor(g.scores.a/10),baseB=24+Math.floor(g.scores.b/10);
      const rewards={a:baseA+(g.winner==='a'?8:g.winner==='draw'?4:0),b:baseB+(g.winner==='b'?8:g.winner==='draw'?4:0),shared};this.state.users.a.coins+=rewards.a;this.state.users.b.coins+=rewards.b;this.state.home.bank+=shared;this.state.home.bankStats.totalDeposited+=shared;this.log('a','甜點廚房共同獎勵：'+shared+' 金幣',shared,'game',{game:'dessert',dessert:g.id});
      g.rewards=rewards;g.memory={title:order.name,grade,final:{a:finalA,b:finalB},text:'做出了 '+grade+' 級 '+order.name+'，甜點品質 '+g.quality+'，默契 '+g.harmony+'，廚房混亂 '+g.chaos+'。'};
    } else g.round++;
  }

  command(id,action,data={}) {
    need(['a','b'].includes(id),'請先登入',401);
    if(action==='position') {this.position(id,data);return;}
    if(action==='task/start') {
      const u=this.state.users[id];need(u.daily.day!==day(this.now())||u.daily.count<3,'今天的三次花園委託已完成');
      this.tasks[id]={step:0,started:this.now()};return;
    }
    if(action==='task/water') {
      const task=this.tasks[id],p=this.presence[id];need(task,'請先接取花園委託');
      need(p&&p.scene==='park'&&this.now()-p.at<10000,'請先走到花園');
      const target=GARDEN[task.step];need(Math.hypot(p.x-target.x,p.z-target.z)<3,'請靠近目前標記的花圃');
      need(this.now()-task.started>=3000&&this.now()-p.gardenSince>=3000,'澆水需要停留片刻，請稍候再試');
      if(task.step<2) {task.step++;task.started=this.now();return;}
      this.transaction(()=>{const u=this.state.users[id];const today=day(this.now());if(u.daily.day!==today)u.daily={day:today,count:0};need(u.daily.count<3,'今日獎勵已達上限');u.daily.count++;u.coins+=25;});
      delete this.tasks[id];return;
    }
    if(action.startsWith('layout/')) return this.layoutCommand(id,action,data);
    return this.transaction(()=>{
      const u=this.state.users[id],h=this.state.home;
      switch(action) {
        case 'quiz/new': {
          this.activeHome();need(!this.state.quiz||Object.values(this.state.quiz.answers).every(Boolean),'已有默契問答進行中');
          this.state.quiz={id:crypto.randomUUID(),answers:{a:null,b:null}};break;
        }
        case 'quiz/answer': {
          this.activeHome();const q=this.state.quiz;need(q&&q.id===data.quizId,'問答已更新');need(!q.answers[id],'你已提交答案');
          need(Array.isArray(data.answers)&&data.answers.length===QUIZ.length&&data.answers.every(x=>integer(x,0,3)),'請回答全部問題');
          q.answers[id]=data.answers.slice();break;
        }
        case 'profile': {
          need(typeof data.name==='string'&&data.name.trim().length>=1&&data.name.trim().length<=12&&!/[\x00-\x1f<>]/.test(data.name),'暱稱需為 1–12 字，不含特殊標記');
          u.name=data.name.trim();break;
        }
        case 'zoo/stamp': {
          const spots=Object.fromEntries(ZOO.map(h=>[h.id,{x:h.entryX,z:h.entryZ}]));
          const target=spots[data.animal],p=this.presence[id];
          need(target&&p&&p.scene==='park'&&this.now()-p.at<3000&&Math.hypot(p.x-target.x,p.z-target.z)<3,'請走到該動物的觀察點');
          if(u.zoo?.day!==day(this.now()))u.zoo={day:day(this.now()),stamps:[]};
          need(!u.zoo.stamps.includes(data.animal),'今天已收集這個印章');
          u.zoo.stamps.push(data.animal);if(u.zoo.stamps.length===3)u.coins+=30;break;
        }
        case 'avatar': {
          const avatar=data.avatar;need(avatar&&BASES.includes(avatar.base),'請選擇有效造型');
          avatar.outfit ??= 'none';
          for(const slot of ['hat','glasses','bag','outfit'])need(avatar[slot]==='none'||(CATALOG_MAP[avatar[slot]]?.type===slot&&this.owns(id,avatar[slot])),'尚未擁有這個配件');
          u.avatar={base:avatar.base,hat:avatar.hat,glasses:avatar.glasses,bag:avatar.bag,outfit:avatar.outfit};break;
        }
        case 'bank/deposit': {
          this.activeHome();need(integer(data.amount,1,100000),'請輸入正整數金額');need(u.coins>=data.amount,'個人金幣不足');
          let goal=null;if(data.goalId){goal=h.goals.find(g=>g.id===data.goalId);need(goal&&goal.status!=='completed','找不到共同目標');}
          u.coins-=data.amount;h.bank+=data.amount;h.bankStats.totalDeposited+=data.amount;if(goal)goal.saved=Math.min(goal.target,goal.saved+data.amount);
          this.log(id,goal?'存入目標：'+goal.title:'存入共同銀行',data.amount,'deposit',{goalId:goal?.id});break;
        }
        case 'bank/gift': {
          need(integer(data.amount,1,GIFT_DAILY_LIMIT),'送禮金額需為 1–50 金幣');need(u.coins>=data.amount,'個人金幣不足');
          const message=String(data.message||'').trim();need(message.length<=30&&!/[<>\x00-\x1f]/.test(message),'小紙條最多 30 字，且不能包含特殊標記');
          if(u.gifts.day!==day(this.now()))u.gifts={day:day(this.now()),sent:0};need(u.gifts.sent+data.amount<=GIFT_DAILY_LIMIT,'今天送禮已達上限');
          u.gifts.sent+=data.amount;u.coins-=data.amount;this.state.users[other(id)].coins+=data.amount;this.log(id,'送給伴侶的小禮物',0,'gift',{amount:data.amount,message});break;
        }
        case 'bank/goal/create': {
          this.activeHome();const title=String(data.title||'').trim(),category=data.category||'other';
          need(title.length>=1&&title.length<=16&&!/[<>\x00-\x1f]/.test(title),'目標名稱需為 1–16 字');need(GOAL_CATEGORIES.includes(category),'目標分類無效');need(integer(data.target,50,1000),'目標金額需為 50–1000');need(h.goals.filter(g=>g.status!=='completed').length<8,'最多同時建立 8 個未完成目標');
          const goal={id:crypto.randomUUID(),title,category,target:data.target,saved:0,status:'active',createdBy:id,createdAt:this.now(),completedAt:null};h.goals.unshift(goal);this.log(id,'建立共同目標：'+title,0,'goal',{goalId:goal.id});break;
        }
        case 'bank/goal/complete': {
          this.activeHome();const goal=h.goals.find(g=>g.id===data.goalId);need(goal&&goal.status!=='completed','找不到共同目標');need(goal.saved>=goal.target,'目標尚未達成');
          goal.status='completed';goal.completedAt=this.now();h.bankStats.goalsCompleted++;this.log(id,'完成共同目標：'+goal.title,0,'goal',{goalId:goal.id});break;
        }
        case 'bank/proposal/withdraw': {
          this.activeHome();need(integer(data.amount,1,100000),'提款金額需為正整數');need(h.bank>=data.amount,'共同銀行餘額不足');const note=String(data.note||'').trim();need(note.length<=30&&!/[<>\x00-\x1f]/.test(note),'提款備註最多 30 字');
          const proposal={id:crypto.randomUUID(),type:'withdraw',status:'pending',createdBy:id,createdAt:this.now(),amount:data.amount,note};h.proposals.unshift(proposal);this.log(id,'提出提款申請',0,'proposal',{proposalId:proposal.id,amount:data.amount});break;
        }
        case 'bank/proposal/approve': {
          this.activeHome();const p=h.proposals.find(p=>p.id===data.proposalId);need(p&&p.status==='pending','找不到待處理提案');need(p.createdBy!==id,'需要伴侶同意');
          if(p.type==='withdraw'){need(h.bank>=p.amount,'共同銀行餘額不足');h.bank-=p.amount;this.state.users[p.createdBy].coins+=p.amount;this.log(id,'同意提款申請',-p.amount,'proposal',{proposalId:p.id});}
          else if(p.type==='purchase'){const item=CATALOG_MAP[p.item];need(item?.type==='furniture','商品已無法共同購買');need(h.bank>=p.amount,'共同銀行餘額不足');h.bank-=p.amount;this.state.users[p.createdBy].inventory.push({instance:crypto.randomUUID(),item:item.id,owner:'shared',buyer:p.createdBy});this.log(id,'同意共同購買：'+item.name,-p.amount,'proposal',{proposalId:p.id,item:item.id});}
          else throw new GameError('提案類型無效');p.status='approved';p.resolvedBy=id;p.resolvedAt=this.now();break;
        }
        case 'bank/proposal/cancel': {
          const p=h.proposals.find(p=>p.id===data.proposalId);need(p&&p.status==='pending','找不到待處理提案');need(p.createdBy===id,'只能取消自己提出的提案');p.status='cancelled';p.resolvedBy=id;p.resolvedAt=this.now();this.log(id,'取消共同提案',0,'proposal',{proposalId:p.id});break;
        }
        case 'purchase': {
          need(typeof data.requestId==='string'&&data.requestId.length>=8&&data.requestId.length<=80,'缺少交易識別碼');
          if(u.receipts.includes(data.requestId))break;
          const item=CATALOG_MAP[data.item];need(item,'找不到商品');
          need(['personal','shared'].includes(data.wallet),'錢包無效');
          const shared=data.wallet==='shared';if(shared){this.activeHome();need(item.type==='furniture','共同銀行只購買家具');}
          if(item.type!=='furniture')need(!this.owns(id,item.id),'已經擁有這個配件');
          need((shared?h.bank:u.coins)>=item.price,'金幣不足');
          if(shared&&item.price>=BANK_APPROVAL_THRESHOLD){
            const proposal={id:crypto.randomUUID(),type:'purchase',status:'pending',createdBy:id,createdAt:this.now(),amount:item.price,item:item.id,note:'共同購買'};h.proposals.unshift(proposal);u.receipts.push(data.requestId);this.log(id,'提出共同購買：'+item.name,0,'proposal',{proposalId:proposal.id,item:item.id,amount:item.price});break;
          }
          if(shared)h.bank-=item.price;else u.coins-=item.price;
          u.inventory.push({instance:crypto.randomUUID(),item:item.id,owner:shared?'shared':id,buyer:id});
          u.receipts.push(data.requestId); // Persist idempotency keys: old successful requests never charge again.
          if(shared)this.log(id,'共同購買：'+item.name,-item.price,'spending',{item:item.id});break;
        }
        case 'home/archive': {
          this.activeHome();need(data.confirm==='ARCHIVE','請確認封存');h.archived=true;this.editLock=null;this.log(id,'封存共同住宅');break;
        }
        case 'game/new': {
          this.activeHome();need(!this.state.game||this.state.game.status==='finished','已有進行中的對局');
          this.state.game={id:crypto.randomUUID(),status:'setup',turn:'a',boards:{a:null,b:null},shots:{a:[],b:[]},winner:null,reason:null};break;
        }
        case 'game/place': {
          const g=this.match(data);need(g.status==='setup','已開始的對局不能重新部署');need(!g.boards[id],'你已完成部署');
          need(Array.isArray(data.ships)&&data.ships.length===3,'需要三艘船');
          const occupied=[];
          for(let i=0;i<3;i++) {
            const s=data.ships[i],length=[3,2,2][i];need(s&&integer(s.x,0,5)&&integer(s.y,0,5)&&['h','v'].includes(s.direction),'艦隊格式錯誤');
            for(let j=0;j<length;j++){const x=s.x+(s.direction==='h'?j:0),y=s.y+(s.direction==='v'?j:0);need(x<6&&y<6,'船艦超出棋盤');const c=y*6+x;need(!occupied.includes(c),'船艦不能重疊');occupied.push(c);}
          }
          g.boards[id]=occupied;if(g.boards.a&&g.boards.b)g.status='playing';break;
        }
        case 'game/fire': {
          const g=this.match(data);need(g.status==='playing'&&g.turn===id,'還沒輪到你');need(integer(data.cell,0,35),'座標無效');need(!g.shots[id].includes(data.cell),'這格已經射擊過');
          g.shots[id].push(data.cell);
          if(g.boards[other(id)].every(c=>g.shots[id].includes(c))) {
            g.status='finished';g.winner=id;g.reason='completed';u.coins+=45;this.state.users[other(id)].coins+=35;
          } else g.turn=other(id);
          break;
        }
        case 'game/surrender': {const g=this.match(data);need(g.status!=='finished','對局已結束');g.status='finished';g.reason='surrender';g.winner=other(id);break;}
        case 'ink/new': {
          this.activeHome();need(!this.state.ink||this.state.ink.status==='finished','已有進行中的墨水大戰');
          this.state.ink={id:crypto.randomUUID(),status:'playing',turn:'a',board:Array(49).fill(null),used:{a:{splash:false,heart:false},b:{splash:false,heart:false}},moves:[],last:null,winner:null,reason:null};break;
        }
        case 'ink/paint': {
          const g=this.inkMatch(data);need(g.status==='playing'&&g.turn===id,'還沒輪到你');
          need(integer(data.cell,0,48),'畫布座標無效');const brush=data.brush||'dot';need(['dot','splash','heart'].includes(brush),'筆刷無效');
          if(brush!=='dot'){need(!g.used[id][brush],'這支特殊筆刷本局已使用');g.used[id][brush]=true;}
          const cells=inkCells(data.cell,brush),before=g.board.slice();
          need(cells.some(c=>g.board[c]!==id),'請選擇能擴張顏色的位置');
          for(const c of cells)g.board[c]=id;
          const gained=g.board.filter((v,i)=>v===id&&before[i]!==id).length;
          g.last={player:id,cell:data.cell,brush,cells,gained};g.moves.push(g.last);g.turn=other(id);
          const counts={a:g.board.filter(x=>x==='a').length,b:g.board.filter(x=>x==='b').length,empty:g.board.filter(x=>!x).length};
          if(g.moves.length>=28||counts.empty===0){
            g.status='finished';g.reason='completed';g.winner=counts.a===counts.b?'draw':(counts.a>counts.b?'a':'b');
            if(g.winner==='draw'){this.state.users.a.coins+=32;this.state.users.b.coins+=32;}
            else {this.state.users[g.winner].coins+=42;this.state.users[other(g.winner)].coins+=30;}
          }
          break;
        }
        case 'ink/surrender': {const g=this.inkMatch(data);need(g.status!=='finished','對局已結束');g.status='finished';g.reason='surrender';g.winner=other(id);break;}

        case 'fold/new': case 'fold/place': case 'fold/drop': case 'fold/surrender': {
          this.activeHome();foldCommand(this.state,id,action,data);break;
        }
        case 'dessert/new': {
          this.activeHome();need(!this.state.dessert||this.state.dessert.status==='finished','已有進行中的甜點廚房');
          this.state.dessert={id:crypto.randomUUID(),status:'playing',round:1,maxRounds:8,orders:DESSERT_ORDERS.map(o=>({...o})),actions:{a:null,b:null},scores:{a:0,b:0},quality:48,harmony:8,chaos:0,log:[],winner:null,reason:null,memory:null,rewards:null};break;
        }
        case 'dessert/play': {
          const g=this.dessertMatch(data);need(g.status==='playing','甜點廚房已結束');need(!g.actions[id],'你已經選好本回合行動');need(DESSERT_CARDS[data.card],'甜點行動不存在');g.actions[id]=data.card;if(g.actions.a&&g.actions.b)this.resolveDessert(g);break;
        }
        case 'dessert/surrender': {const g=this.dessertMatch(data);need(g.status!=='finished','甜點廚房已結束');g.status='finished';g.reason='surrender';g.winner=other(id);break;}
        case 'number/new': {
          this.activeHome();need(!this.state.numberHunt||this.state.numberHunt.status==='finished','已有進行中的找數字競速');
          this.state.numberHunt={id:crypto.randomUUID(),status:'waiting',invitedBy:id,round:0,target:null,board:[],scores:{a:0,b:0},winner:null,reason:null,last:null,history:[],lockUntil:{a:0,b:0},goal:5,rewards:null};break;
        }
        case 'number/accept': {
          const g=this.numberHuntMatch(data);need(g.status==='waiting','邀請已失效');need(g.invitedBy!==id,'請等待伴侶接受邀請');
          g.status='playing';g.round=1;nextNumberRound(g);break;
        }
        case 'number/decline': {
          const g=this.numberHuntMatch(data);need(g.status==='waiting','邀請已失效');need(g.invitedBy!==id,'只有受邀者可以婉拒');
          g.status='finished';g.reason='declined';break;
        }
        case 'number/cancel': {
          const g=this.numberHuntMatch(data);need(g.status==='waiting','邀請已失效');need(g.invitedBy===id,'只有邀請者可以取消');
          g.status='finished';g.reason='cancelled';break;
        }
        case 'number/pick': {
          const g=this.numberHuntMatch(data);need(g.status==='playing','找數字競速已結束');need(data.round===g.round,'這一題已經換了');
          need(integer(data.value,1,48)&&g.board.includes(data.value),'數字不在題目中');need(this.now()>=(g.lockUntil[id]||0),'答錯後請停一下再找');
          const correct=data.value===g.target;g.last={player:id,value:data.value,correct,round:g.round,at:this.now()};g.history.push(g.last);
          if(!correct){g.lockUntil[id]=this.now()+500;break;}
          g.scores[id]++;
          if(g.scores[id]>=g.goal){
            g.status='finished';g.reason='completed';g.winner=id;g.rewards={[id]:30,[other(id)]:25};this.state.users[id].coins+=30;this.state.users[other(id)].coins+=25;
          } else {g.round++;nextNumberRound(g);}
          break;
        }
        case 'number/surrender': {
          const g=this.numberHuntMatch(data);need(g.status==='playing','找數字競速已結束');g.status='finished';g.reason='surrender';g.winner=other(id);break;
        }
        case 'flick/new': {
          this.activeHome();need(!this.state.flick||this.state.flick.status==='finished','已有進行中的圓片彈射');
          this.state.flick={id:crypto.randomUUID(),status:'waiting',invitedBy:id,turn:null,pucks:flickPucks(),scores:{a:0,b:0},winner:null,reason:null,shots:0,last:null,rewards:null};break;
        }
        case 'flick/accept': {
          const g=this.flickMatch(data);need(g.status==='waiting','邀請已失效');need(g.invitedBy!==id,'請等待伴侶接受邀請');g.status='playing';g.turn=g.invitedBy;break;
        }
        case 'flick/decline': {
          const g=this.flickMatch(data);need(g.status==='waiting','邀請已失效');need(g.invitedBy!==id,'只有受邀者可以婉拒');g.status='finished';g.reason='declined';break;
        }
        case 'flick/cancel': {
          const g=this.flickMatch(data);need(g.status==='waiting','邀請已失效');need(g.invitedBy===id,'只有邀請者可以取消');g.status='finished';g.reason='cancelled';break;
        }
        case 'flick/shoot': {
          const g=this.flickMatch(data);need(g.status==='playing','圓片彈射已結束');need(g.turn===id,'還沒輪到你');
          const puck=g.pucks.find(p=>p.id===data.puckId);need(puck&&puck.owner===id&&!puck.scored,'請選擇自己的場上圓片');
          need(Number.isFinite(data.vx)&&Number.isFinite(data.vy),'彈射方向無效');const speed=Math.hypot(data.vx,data.vy);need(speed>=1.5&&speed<=FLICK_RULES.maxSpeed,'拖曳距離太短或力道太大');
          const from=g.pucks.filter(p=>!p.scored).map(p=>[p.id,p.x,p.y]),result=simulateFlick(g.pucks,puck,data.vx,data.vy);g.shots++;
          g.scores={a:g.pucks.filter(p=>p.owner==='a'&&p.scored).length,b:g.pucks.filter(p=>p.owner==='b'&&p.scored).length};
          g.last={key:g.id+':'+g.shots,player:id,puck:puck.id,from,frames:result.frames,scored:result.scored};
          const complete=['a','b'].filter(pid=>g.scores[pid]>=FLICK_RULES.goalScore);
          if(complete.length){
            g.status='finished';g.reason='completed';g.winner=complete.length===2?'draw':complete[0];
            if(g.winner==='draw'){g.rewards={a:38,b:38};this.state.users.a.coins+=38;this.state.users.b.coins+=38;}
            else {g.rewards={[g.winner]:45,[other(g.winner)]:35};this.state.users[g.winner].coins+=45;this.state.users[other(g.winner)].coins+=35;}
          } else g.turn=other(id);
          break;
        }
        case 'flick/surrender': {
          const g=this.flickMatch(data);need(g.status==='playing','圓片彈射已結束');g.status='finished';g.reason='surrender';g.winner=other(id);break;
        }
        default: throw new GameError('不支援的操作',404);
      }
    }, ({purchase:'購買：'+(CATALOG_MAP[data.item]?.name||''),'bank/deposit':'存入共同銀行','bank/gift':'送禮轉帳','bank/proposal/approve':'共同提案完成','game/fire':'海戰棋完賽獎勵','ink/paint':'墨水大戰完賽獎勵','dessert/play':'甜點廚房完賽獎勵','number/pick':'找數字競速完賽獎勵','flick/shoot':'圓片彈射完賽獎勵','zoo/stamp':'動物園手帳獎勵'})[action]||'遊戲獎勵');
  }
  match(data) {const g=this.state.game;need(g&&g.id===data.gameId,'對局已更新，請重新整理');return g;}
  inkMatch(data) {const g=this.state.ink;need(g&&g.id===data.gameId,'墨水對局已更新，請重新整理');return g;}
  dessertMatch(data) {const g=this.state.dessert;need(g&&g.id===data.gameId,'甜點廚房已更新，請重新整理');return g;}
  numberHuntMatch(data) {const g=this.state.numberHunt;need(g&&g.id===data.gameId,'找數字題目已更新，請重新整理');return g;}
  flickMatch(data) {const g=this.state.flick;need(g&&g.id===data.gameId,'圓片桌已更新，請重新整理');return g;}
  layoutCommand(id,action,data) {
    this.activeHome();const lock=this.liveLock();
    if(action==='layout/lock'){need(!lock||lock.user===id,'伴侶正在布置，請稍候',409);this.editLock={user:id,expires:this.now()+90000};return;}
    need(lock?.user===id,'編輯鎖已到期，請重新進入布置',409);
    if(action==='layout/heartbeat'){this.editLock.expires=this.now()+90000;return;}
    if(action==='layout/cancel'){this.editLock=null;return;}
    if(action==='layout/save'||action==='layout/undo') {
      const h=this.state.home;need(data.revision===h.revision,'配置已更新，請重新載入',409);
      const placements=action==='layout/undo'?h.previous:data.layout;
      this.validateLayout(id,placements);
      this.transaction(()=>{const old=h.layout;h.layout=structuredClone(placements);h.previous=old;h.revision++;this.log(id,action==='layout/undo'?'恢復上一版布置':'保存家庭布置');});
      this.editLock=null;return;
    }
    throw new GameError('不支援的布置操作');
  }
  validateLayout(id,layout) {
    need(Array.isArray(layout)&&layout.length<=24,'最多擺放 24 件家具');
    const inventory=Object.values(this.state.users).flatMap(u=>u.inventory),used=new Set(),rects=[];
    for(const placement of layout) {
      const owned=inventory.find(i=>i.instance===placement.instance),item=CATALOG_MAP[owned?.item];
      need(item?.type==='furniture','不存在的家具');
      const already=this.state.home.layout.some(p=>p.instance===placement.instance);
      need(owned.owner==='shared'||owned.owner===id||already,'不能拿取伴侶尚未擺放的個人物品');
      need(!used.has(placement.instance),'不能重複擺放同一件家具');used.add(placement.instance);
      need(Number.isFinite(placement.x)&&Number.isFinite(placement.z)&&[0,90,180,270].includes(placement.rotation),'家具座標錯誤');
      need(Number.isInteger(placement.x*2)&&Number.isInteger(placement.z*2),'請對齊半格格線');
      const rotated=placement.rotation%180!==0,w=rotated?item.depth:item.width,d=rotated?item.width:item.depth;
      const r={x:placement.x-w/2,z:placement.z-d/2,w,d};
      need(ZONES.some(a=>r.x>=a.x&&r.z>=a.z&&r.x+w<=a.x+a.width&&r.z+d<=a.z+a.depth),'家具必須放在標示的布置區，不能堵住通道');
      need(!rects.some(a=>r.x<a.x+a.w&&r.x+r.w>a.x&&r.z<a.z+a.d&&r.z+r.d>a.z),'家具互相重疊');rects.push(r);
    }
  }
}



