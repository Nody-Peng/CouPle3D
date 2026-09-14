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
export function initialState() {
  const user = (name,base) => ({name,coins:120,avatar:{base,hat:'none',glasses:'none',bag:'none'},inventory:[],daily:{day:'',count:0},receipts:[]});
  return {version:1,users:{a:user('小晴','female-a'),b:user('阿澄','male-a')},home:{bank:0,archived:false,layout:[],previous:[],revision:0,ledger:[]},game:null};
}
export class Store {
  constructor(file, options={}) {
    this.file=file; this.now=options.now || Date.now; this.state=fs.existsSync(file) ? JSON.parse(fs.readFileSync(file,'utf8')) : initialState();
    need(this.state.version===1,'不支援的存檔版本',500);
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
  log(id,text,amount=0) {
    this.state.home.ledger.unshift({id:crypto.randomUUID(),at:this.now(),user:id,text,amount});
    this.state.home.ledger=this.state.home.ledger.slice(0,100);
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
      game,task:this.tasks[id]||null,today:day(this.now())};
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
          for(const slot of ['hat','glasses','bag'])need(avatar[slot]==='none'||(CATALOG_MAP[avatar[slot]]?.type===slot&&this.owns(id,avatar[slot])),'尚未擁有這個配件');
          u.avatar={base:avatar.base,hat:avatar.hat,glasses:avatar.glasses,bag:avatar.bag};break;
        }
        case 'bank/deposit': {
          this.activeHome();need(integer(data.amount,1,100000),'請輸入正整數金額');need(u.coins>=data.amount,'個人金幣不足');
          u.coins-=data.amount;h.bank+=data.amount;this.log(id,'存入共同銀行',data.amount);break;
        }
        case 'purchase': {
          need(typeof data.requestId==='string'&&data.requestId.length>=8&&data.requestId.length<=80,'缺少交易識別碼');
          if(u.receipts.includes(data.requestId))break;
          const item=CATALOG_MAP[data.item];need(item,'找不到商品');
          need(['personal','shared'].includes(data.wallet),'錢包無效');
          const shared=data.wallet==='shared';if(shared){this.activeHome();need(item.type==='furniture','共同銀行只購買家具');}
          if(item.type!=='furniture')need(!this.owns(id,item.id),'已經擁有這個配件');
          need((shared?h.bank:u.coins)>=item.price,'金幣不足');
          if(shared)h.bank-=item.price;else u.coins-=item.price;
          u.inventory.push({instance:crypto.randomUUID(),item:item.id,owner:shared?'shared':id,buyer:id});
          u.receipts.push(data.requestId); // Persist idempotency keys: old successful requests never charge again.
          if(shared)this.log(id,'共同購買：'+item.name,-item.price);break;
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
        default: throw new GameError('不支援的操作',404);
      }
    }, ({purchase:'購買：'+(CATALOG_MAP[data.item]?.name||''),'bank/deposit':'存入共同銀行','game/fire':'海戰棋完賽獎勵','zoo/stamp':'動物園手帳獎勵'})[action]||'遊戲獎勵');
  }
  match(data) {const g=this.state.game;need(g&&g.id===data.gameId,'對局已更新，請重新整理');return g;}
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



