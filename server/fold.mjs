import {randomUUID} from 'node:crypto';
import {GameError} from './store.mjs';
const check=(ok,msg)=>{if(!ok)throw new GameError(msg);};
const other=id=>id==='a'?'b':'a';
const finite=(v,min,max)=>Number.isFinite(v)&&v>=min&&v<=max;
export const FOLD_RULES=Object.freeze({width:160,height:110,figureRadius:3,inkRadius:1.25,figureScale:.12,margin:6,separation:12,maxRounds:30});
const LEGACY_RULES={width:100,height:100,figureRadius:7,inkRadius:3,figureScale:.3,margin:10,separation:22,maxRounds:30};
const rulesFor=g=>g.version===2?FOLD_RULES:LEGACY_RULES;
export function foldSnapshot(g,id){
  if(!g)return null;
  const result=structuredClone(g);
  result.rules={...rulesFor(g)};
  if(g.status==='setup')result.figures[other(id)]=g.figures[other(id)]?[]:null;
  if(g.version===2){
    // An uncommitted opponent shot must never leak through HTTP or SSE.
    result.ownPending=structuredClone(g.pending[id]);
    result.partnerReady=!!g.pending[other(id)];
    delete result.pending;
  }
  return result;
}
function finish(state,g,winner,reason){
  g.status='finished';g.winner=winner;g.reason=reason;
  for(const p of ['a','b'])state.users[p].coins+=winner==='draw'?30:winner===p?40:25;
}
function resolveShot(g,id,shot,rules,round){
  const hits=[],distances=[];
  g.figures[other(id)].forEach((f,i)=>{
    if(f.hit)return;
    const distance=Math.hypot(f.x-(rules.width-shot.x),f.y-shot.y);
    distances.push(distance);
    if(distance<=rules.figureRadius+rules.inkRadius){f.hit=true;hits.push(i);}
  });
  return {player:id,x:shot.x,y:shot.y,hits,round,near:!hits.length&&Math.min(...distances)<=rules.figureRadius+rules.inkRadius+2};
}
export function foldCommand(state,id,action,data={}){
  if(action==='fold/new'){
    check(!state.fold||state.fold.status==='finished','已有進行中的對折墨水戰');
    state.fold={id:randomUUID(),version:2,status:'setup',round:1,pending:{a:null,b:null},figures:{a:null,b:null},shots:[],winner:null};return;
  }
  const g=state.fold,enemy=other(id);
  check(g&&g.id===data.gameId,'紙張已更新，請重新開啟遊戲');
  check(g.status!=='finished','對局已結束');
  const rules=rulesFor(g);
  if(action==='fold/surrender'){g.status='finished';g.winner=enemy;g.reason='surrender';if(g.pending)g.pending={a:null,b:null};return;}
  if(action==='fold/place'){
    check(g.status==='setup'&&!g.figures[id],'已經封好畫紙');
    check(Array.isArray(data.figures)&&data.figures.length===3,'請畫出並放好三個小人');
    const figures=data.figures.map(f=>{
      check(f&&finite(f.x,rules.margin,rules.width-rules.margin)&&finite(f.y,rules.margin,rules.height-rules.margin),'小人要留在紙張邊界內');
      check(Array.isArray(f.strokes)&&f.strokes.length>0&&f.strokes.length<=20,'請先畫好小人');
      let count=0;
      const strokes=f.strokes.map(line=>{check(Array.isArray(line)&&line.length>=2,'筆畫太短');count+=line.length;check(count<=240,'筆畫過多，請簡化小人');return line.map(p=>{check(Array.isArray(p)&&p.length===2&&finite(p[0],0,40)&&finite(p[1],0,50),'筆畫超出畫框');return [p[0],p[1]];});});
      return {x:f.x,y:f.y,strokes,hit:false};
    });
    check(figures.every((f,i)=>figures.slice(i+1).every(b=>Math.hypot(f.x-b.x,f.y-b.y)>=rules.separation)),'小人要相隔至少一個身位');
    g.figures[id]=figures;if(g.figures.a&&g.figures.b)g.status='playing';return;
  }
  check(action==='fold/drop'&&g.status==='playing','尚未開始落墨');
  const margin=rules.inkRadius;
  check(finite(data.x,margin,rules.width-margin)&&finite(data.y,margin,rules.height-margin),'請在自己的紙上落墨');
  check(!g.shots.some(s=>s.player===id&&Math.hypot(s.x-data.x,s.y-data.y)<(g.version===2?rules.inkRadius:4)),'這裡已經滴過墨水，換個位置吧');
  if(g.version===2){
    check(data.round===g.round,'回合已更新，請重新開啟畫紙');
    check(!g.pending[id],'你已封好這一滴，請等伴侶');
    g.pending[id]={x:data.x,y:data.y};
    if(!g.pending.a||!g.pending.b)return;
    // Resolve both attacks before checking the result: a defeated team still fires.
    const shots=['a','b'].map(p=>resolveShot(g,p,g.pending[p],rules,g.round));
    g.shots.push(...shots);g.pending={a:null,b:null};
    const a=g.figures.b.filter(f=>f.hit).length,b=g.figures.a.filter(f=>f.hit).length;
    if(a===3||b===3||g.round>=rules.maxRounds){
      finish(state,g,a===b?'draw':a>b?'a':'b',a===3||b===3?'completed':'limit');
    }else g.round++;
    return;
  }
  // Existing saved games keep their original rules until both players finish.
  check(g.turn===id,'還沒輪到你落墨');check(data.shotNumber===g.shots.length,'這一滴已處理，請等畫紙展開');
  g.shots.push(resolveShot(g,id,data,rules,Math.floor(g.shots.length/2)+1));g.turn=enemy;
  const a=g.figures.b.filter(f=>f.hit).length,b=g.figures.a.filter(f=>f.hit).length;
  if(g.figures[enemy].every(f=>f.hit))finish(state,g,id,'completed');
  else if(g.shots.length>=60)finish(state,g,a===b?'draw':a>b?'a':'b','limit');
}
