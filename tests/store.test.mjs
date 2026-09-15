import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {Store} from '../server/store.mjs';
import {createApp} from '../server/server.mjs';
import {ZOO,BASES} from '../server/catalog.mjs';

function fixture(t){const dir=fs.mkdtempSync(path.join(os.tmpdir(),'couple-test-'));t.after(()=>{const resolved=path.resolve(dir);assert.equal(path.dirname(resolved),path.resolve(os.tmpdir()));assert.ok(path.basename(resolved).startsWith('couple-test-'));fs.rmSync(resolved,{recursive:true,force:true});});let time=Date.UTC(2026,8,8);const file=path.join(dir,'state.json');return {store:new Store(file,{now:()=>time}),file,tick:ms=>time+=ms};}
const buy=(s,id,item,wallet='personal',requestId='purchase-'+Math.random())=>s.command(id,'purchase',{item,wallet,requestId});
const ships=[{x:0,y:0,direction:'h'},{x:0,y:2,direction:'h'},{x:3,y:4,direction:'v'}];
function game(s){s.command('a','game/new');const gameId=s.state.game.id;for(const id of ['a','b'])s.command(id,'game/place',{gameId,ships});return gameId;}

test('purchases, ownership, balance checks and permanent idempotency survive restart',t=>{
  const {store:s,file}=fixture(t);buy(s,'a','hat_beret','personal','stable-request');assert.equal(s.state.users.a.coins,70);
  buy(s,'a','hat_beret','personal','stable-request');assert.equal(s.state.users.a.coins,70);
  assert.throws(()=>buy(s,'a','hat_bunny'),/不足/);assert.equal(s.state.users.a.coins,70);
  assert.throws(()=>s.command('b','avatar',{avatar:{base:'male-a',hat:'hat_beret',glasses:'none',bag:'none'}}),/擁有/);
  s.command('a','avatar',{avatar:{base:'male-b',hat:'hat_beret',glasses:'none',bag:'none'}});
  const restored=new Store(file);assert.equal(restored.state.users.a.avatar.base,'male-b');
  buy(restored,'a','hat_beret','personal','stable-request');assert.equal(restored.state.users.a.coins,70);
});
test('bank stores deposits, requires approval for large shared purchases, and keeps an audit trail',t=>{
  const {store:s}=fixture(t);s.command('a','bank/deposit',{amount:60});s.command('b','bank/deposit',{amount:60});
  buy(s,'a','plant_leaf','shared');assert.equal(s.state.home.bank,85);
  s.command('b','bank/deposit',{amount:30});
  buy(s,'a','sofa_rose','shared','sofa-proposal');assert.equal(s.state.home.bank,115);assert.equal(s.state.home.proposals[0].type,'purchase');
  assert.throws(()=>s.command('a','bank/proposal/approve',{proposalId:s.state.home.proposals[0].id}),/伴侶/);
  s.command('b','bank/proposal/approve',{proposalId:s.state.home.proposals[0].id});
  assert.equal(s.state.home.bank,5);assert.ok(s.state.users.a.inventory.some(i=>i.item==='sofa_rose'&&i.owner==='shared'));
  assert.throws(()=>s.command('b','bank/deposit',{amount:-1}));assert.throws(()=>s.command('b','bank/withdraw',{amount:5}));
  assert.throws(()=>buy(s,'b','hat_beret','shared'),/家具/);
});
test('furniture lock, layout validation, shared visibility, revision and undo',t=>{
  const {store:s,tick}=fixture(t);buy(s,'a','sofa_rose');const instance=s.state.users.a.inventory[0].instance;
  s.command('a','layout/lock');assert.throws(()=>s.command('b','layout/lock'),/正在布置/);
  assert.throws(()=>s.command('a','layout/save',{revision:0,layout:[{instance,x:0,z:0,rotation:0}]}),/布置區/);
  s.command('a','layout/save',{revision:0,layout:[{instance,x:0,z:12.5,rotation:0}]});
  assert.equal(s.state.home.revision,1);assert.ok(s.snapshot('b').homeInventory.some(i=>i.instance===instance));
  s.command('b','layout/lock');s.command('b','layout/save',{revision:1,layout:[{instance,x:1,z:12.5,rotation:0}]});
  s.command('a','layout/lock');s.command('a','layout/undo',{revision:2});assert.equal(s.state.home.layout[0].x,0);
  s.command('b','layout/lock');tick(90001);assert.throws(()=>s.command('b','layout/save',{revision:3,layout:[]}),/到期/);
  s.command('a','layout/lock');assert.throws(()=>s.command('a','layout/save',{revision:0,layout:[]}),/更新/);
});
test('unplaced personal furniture cannot be taken by partner; overlap is rejected',t=>{
  const {store:s}=fixture(t);buy(s,'a','plant_leaf');buy(s,'a','plant_leaf');const [a,b]=s.state.users.a.inventory;
  s.command('b','layout/lock');assert.throws(()=>s.command('b','layout/save',{revision:0,layout:[{instance:a.instance,x:0,z:12,rotation:0}]}),/不能拿取/);s.command('b','layout/cancel');
  s.command('a','layout/lock');assert.throws(()=>s.command('a','layout/save',{revision:0,layout:[a,b].map(i=>({instance:i.instance,x:0,z:12,rotation:0}))}),/重疊/);
});
test('battleship hides enemy board, enforces turns and rewards exactly once after restart',t=>{
  const {store:s,file}=fixture(t);const gameId=game(s);assert.equal(s.snapshot('a').game.enemyBoard,undefined);
  assert.throws(()=>s.command('b','game/fire',{gameId,cell:0}),/輪到/);
  s.command('a','game/fire',{gameId,cell:0});const restored=new Store(file);
  assert.deepEqual(restored.snapshot('a').game.ownShots,[{cell:0,hit:true,sunk:false}]);
  const hits=[1,2,12,13,27,33],misses=[5,11,17,23,29,35];
  for(let i=0;i<hits.length;i++){restored.command('b','game/fire',{gameId,cell:misses[i]});restored.command('a','game/fire',{gameId,cell:hits[i]});}
  assert.equal(restored.state.game.winner,'a');assert.equal(restored.state.users.a.coins,165);assert.equal(restored.state.users.b.coins,155);
  assert.throws(()=>restored.command('a','game/fire',{gameId,cell:34}));assert.equal(restored.state.users.a.coins,165);
});
test('surrender pays nothing; invalid fleet and stale game requests are rejected',t=>{
  const {store:s}=fixture(t);s.command('a','game/new');const gameId=s.state.game.id;
  assert.throws(()=>s.command('a','game/place',{gameId,ships:[ships[0],ships[0],ships[0]]}),/重疊/);
  s.command('b','game/surrender',{gameId});assert.equal(s.state.users.a.coins,120);
  s.command('a','game/new');assert.throws(()=>s.command('a','game/place',{gameId,ships}),/更新/);
});
test('daily gardening requires location and dwell, caps at three and persists',t=>{
  const {store:s,tick,file}=fixture(t);
  for(let round=0;round<3;round++){
    s.command('a','task/start');assert.throws(()=>s.command('a','task/water'),/花園/);
    for(const x of [-20,-10,12]){tick(10000);s.command('a','position',{x,z:35,scene:'park'});assert.throws(()=>s.command('a','task/water'),/停留/);tick(3100);s.command('a','task/water');}
    delete s.presence.a;
  }
  assert.equal(s.state.users.a.coins,195);assert.throws(()=>s.command('a','task/start'),/已完成/);
  const restored=new Store(file);assert.equal(restored.state.users.a.daily.count,3);
});
test('archive freezes shared assets and preserves personal inventory',t=>{
  const {store:s}=fixture(t);buy(s,'a','hat_beret');s.command('a','bank/deposit',{amount:50});s.command('a','home/archive',{confirm:'ARCHIVE'});
  assert.throws(()=>s.command('b','layout/lock'),/封存/);assert.throws(()=>s.command('a','bank/deposit',{amount:1}),/封存/);
  assert.equal(s.state.home.bank,50);assert.equal(s.state.users.a.inventory.length,1);
});
test('HTTP authentication, session isolation, path containment and durable API commands',async t=>{
  const {file}=fixture(t);const {server}=createApp({file,accessCode:'test-only'});await new Promise(r=>server.listen(0,'127.0.0.1',r));
  t.after(()=>server.close());const base=`http://127.0.0.1:${server.address().port}`;
  const post=(route,data,cookie='',origin='')=>fetch(base+'/api/'+route,{method:'POST',headers:{'Content-Type':'application/json',Cookie:cookie,...(origin?{Origin:origin}:{})},body:JSON.stringify(data)});
  assert.equal((await fetch(base+'/api/state')).status,401);
  const a=await post('login',{id:'a',code:'test-only'}),cookie=a.headers.get('set-cookie').split(';')[0];assert.match(a.headers.get('set-cookie'),/HttpOnly/);
  assert.equal((await post('bank/deposit',{amount:10},cookie,'https://attacker.invalid')).status,403);
  const purchase=await post('purchase',{item:'plant_leaf',wallet:'personal',requestId:'http-unique'},cookie);assert.equal(purchase.status,200);assert.equal((await purchase.json()).user.coins,85);
  assert.equal((await fetch(base+'/server/data/state.json')).status,404);
  const b=await post('login',{id:'b',code:'test-only'});assert.equal((await b.json()).user.coins,120);
});

test('zoo stamps require proximity, reward once daily, persist, and ledger records spending',t=>{
  const {store:s,file,tick}=fixture(t);
  assert.throws(()=>s.command('a','zoo/stamp',{animal:'panda'}),/觀察點/);
  for(const [animal,x,z] of ZOO.slice(0,3).map(h=>[h.id,h.entryX,h.entryZ])){
    tick(2000);s.command('a','position',{x,z,scene:'park'});s.command('a','zoo/stamp',{animal});
    assert.throws(()=>s.command('a','zoo/stamp',{animal}),/已收集/);
  }
  assert.equal(s.state.users.a.coins,150);
  const restored=new Store(file);assert.equal(restored.state.users.a.zoo.stamps.length,3);
  assert.equal(restored.state.users.a.ledger[0].amount,30);
  buy(restored,'a','hat_beret');assert.equal(restored.state.users.a.ledger[0].amount,-50);
  assert.equal(restored.state.users.a.ledger[0].balance,100);
  s.command('a','profile',{name:'花園旅人'});assert.equal(s.snapshot('b').partner.name,'花園旅人');
  assert.throws(()=>s.command('a','profile',{name:'<script>'}),/暱稱/);
  assert.throws(()=>s.command('a','position',{x:160,z:0,scene:'park'}),/超出/);
});

test('quiz answers are private until both submit and reconnect without coin rewards',t=>{
  const {store:s,file}=fixture(t);s.command('a','quiz/new');const quizId=s.state.quiz.id;
  s.command('a','quiz/answer',{quizId,answers:[0,1,2]});
  assert.equal(s.snapshot('b').quiz.answers,null);assert.equal(s.snapshot('b').quiz.results,null);
  assert.throws(()=>s.command('a','quiz/new'),/進行中/);
  const restored=new Store(file);restored.command('b','quiz/answer',{quizId,answers:[0,2,2]});
  assert.deepEqual(restored.snapshot('a').quiz.results.b,[0,2,2]);assert.equal(restored.state.users.a.coins,120);
  assert.throws(()=>restored.command('b','quiz/answer',{quizId,answers:[0,2,2]}),/提交/);
});


test('all twelve looks persist; six zoo habitats share one daily reward',t=>{
 const {store:s,tick,file}=fixture(t);assert.equal(BASES.length,12);assert.equal(ZOO.length,6);
 for(const base of BASES)s.command('a','avatar',{avatar:{base,hat:'none',glasses:'none',bag:'none'}});
 assert.equal(new Store(file).state.users.a.avatar.base,BASES.at(-1));
 for(const h of ZOO){tick(2000);s.command('a','position',{x:h.entryX,z:h.entryZ,scene:'park'});s.command('a','zoo/stamp',{animal:h.id});}
 assert.equal(s.state.users.a.coins,150);assert.equal(s.state.users.a.zoo.stamps.length,6);
 assert.equal(s.state.users.a.ledger.filter(e=>e.amount===30).length,1);
 tick(86400000);
 for(const h of ZOO.slice(3)){tick(2000);s.command('a','position',{x:h.entryX,z:h.entryZ,scene:'park'});s.command('a','zoo/stamp',{animal:h.id});}
 assert.equal(s.state.users.a.coins,180);
});

test('arrival forecourt accepts its bounded extension only',t=>{
 const {store:s,tick}=fixture(t);
 s.command('a','position',{x:0,z:53,scene:'park'});
 tick(2000);assert.throws(()=>s.command('a','position',{x:20,z:53,scene:'park'}),/超出/);
 assert.throws(()=>s.command('a','position',{x:0,z:57,scene:'park'}),/超出/);
});

test('sunk ships reveal only fully hit cells and survive reconnect',t=>{
 const {store:s,file}=fixture(t),gameId=game(s);
 assert.deepEqual(s.snapshot('a').game.enemySunk,[]);
 for(const [hit,miss] of [[0,5],[1,11],[2,17]]){
  s.command('a','game/fire',{gameId,cell:hit});
  if(hit!==2)assert.deepEqual(s.snapshot('a').game.enemySunk,[]);
  s.command('b','game/fire',{gameId,cell:miss});
 }
 const g=s.snapshot('a').game;
 assert.deepEqual(g.enemySunk,[[0,1,2]]);assert.equal(g.ownShots.at(-1).sunk,true);
 assert.equal(g.enemyBoard,undefined);assert.equal(g.ownShots[0].sunk,false);
 assert.deepEqual(new Store(file).snapshot('a').game.enemySunk,[[0,1,2]]);
});


test('outfits enforce ownership, allow free starter, persist and remain compatible with old avatars',t=>{
 const {store:s,file}=fixture(t);
 const avatar={base:'female-c',hat:'none',glasses:'none',bag:'none',outfit:'outfit_rose'};
 assert.throws(()=>s.command('a','avatar',{avatar}),/擁有/);
 buy(s,'a','outfit_cream');assert.equal(s.state.users.a.coins,120);
 buy(s,'a','outfit_rose');s.command('a','avatar',{avatar});
 const restored=new Store(file);assert.equal(restored.snapshot('b').partner.avatar.outfit,'outfit_rose');
 assert.throws(()=>restored.command('b','avatar',{avatar}),/擁有/);
 assert.throws(()=>restored.command('a','avatar',{avatar:{...avatar,outfit:'hat_beret'}}),/擁有/);
 const {outfit,...legacy}=avatar;restored.command('a','avatar',{avatar:legacy});
 assert.equal(restored.state.users.a.avatar.outfit,'none');
});


test('ink duel persists turns, limits special brushes, finishes with one reward',t=>{
 const {store:s,file}=fixture(t);
 s.command('a','ink/new');const gameId=s.state.ink.id;
 assert.equal(s.snapshot('a').ink.board.length,49);
 assert.throws(()=>s.command('b','ink/paint',{gameId,cell:0,brush:'dot'}),/輪到/);
 s.command('a','ink/paint',{gameId,cell:24,brush:'splash'});
 assert.equal(s.snapshot('a').ink.used.splash,true);
 assert.equal(s.snapshot('a').ink.counts.a,5);
 const restored=new Store(file);
 assert.equal(restored.snapshot('b').ink.partnerUsed.splash,true);
 assert.throws(()=>restored.command('a','ink/paint',{gameId,cell:25,brush:'heart'}),/輪到/);
 restored.command('b','ink/paint',{gameId,cell:0,brush:'heart'});
 assert.throws(()=>restored.command('a','ink/paint',{gameId,cell:24,brush:'splash'}),/已使用/);
 while(restored.state.ink.status==='playing'){
  const id=restored.state.ink.turn;
  const cell=restored.state.ink.board.findIndex(x=>x!==id);
  restored.command(id,'ink/paint',{gameId,cell,brush:'dot'});
 }
 const coins={a:restored.state.users.a.coins,b:restored.state.users.b.coins},winner=restored.state.ink.winner;
 assert.ok(['a','b','draw'].includes(winner));
 assert.equal(coins.a+coins.b,winner==='draw'?304:312);
 assert.throws(()=>restored.command(restored.state.ink.turn,'ink/paint',{gameId,cell:1,brush:'dot'}),/還沒輪到|對局已結束/);
 assert.deepEqual({a:restored.state.users.a.coins,b:restored.state.users.b.coins},coins);
});


test('bank goals, gifts, withdrawal proposals and legacy migration work',t=>{
 const {store:s,file,tick}=fixture(t);
 s.command('a','bank/goal/create',{title:'約會基金',category:'date',target:80});const goalId=s.state.home.goals[0].id;
 assert.throws(()=>s.command('a','bank/goal/complete',{goalId}),/尚未達成/);
 s.command('a','bank/deposit',{amount:50,goalId});s.command('b','bank/deposit',{amount:40,goalId});
 assert.equal(s.state.home.bank,90);assert.equal(s.state.home.goals[0].saved,80);
 s.command('b','bank/goal/complete',{goalId});assert.equal(s.state.home.bankStats.goalsCompleted,1);
 s.command('a','bank/gift',{amount:30,message:'買杯咖啡'});assert.equal(s.state.users.a.coins,40);assert.equal(s.state.users.b.coins,110);
 assert.throws(()=>s.command('a','bank/gift',{amount:21,message:'再一點'}),/上限/);
 tick(86400000);s.command('a','bank/gift',{amount:40,message:'明天的小禮物'});
 s.command('b','bank/proposal/withdraw',{amount:20,note:'買花'});const proposalId=s.state.home.proposals[0].id;
 assert.throws(()=>s.command('b','bank/proposal/approve',{proposalId}),/伴侶/);
 s.command('a','bank/proposal/approve',{proposalId});assert.equal(s.state.home.bank,70);assert.equal(s.state.users.b.coins,170);
 const restored=new Store(file);assert.equal(restored.snapshot('a').bank.stats.goalsCompleted,1);assert.equal(restored.snapshot('a').bank.gift.limit,50);
 const legacy=JSON.parse(fs.readFileSync(file,'utf8'));delete legacy.home.goals;delete legacy.home.proposals;delete legacy.home.bankStats;delete legacy.users.a.gifts;fs.writeFileSync(file,JSON.stringify(legacy));
 const migrated=new Store(file);assert.deepEqual(migrated.state.home.goals,[]);assert.equal(migrated.state.home.bankStats.totalDeposited,90);assert.equal(migrated.state.users.a.gifts.sent,0);
});
