import {randomUUID} from 'node:crypto';
import {GameError} from './store.mjs';
const check=(ok,msg)=>{if(!ok)throw new GameError(msg);};
const other=id=>id==='a'?'b':'a';
const finite=(v,min,max)=>Number.isFinite(v)&&v>=min&&v<=max;
export function foldSnapshot(g,id){
  if(!g)return null;
  const result=structuredClone(g);
  if(g.status==='setup')result.figures[other(id)]=g.figures[other(id)]?[]:null;
  return result;
}
export function foldCommand(state,id,action,data={}){
  if(action==='fold/new'){
    check(!state.fold||state.fold.status==='finished','已有進行中的對折墨水戰');
    state.fold={id:randomUUID(),status:'setup',turn:Math.random()<.5?'a':'b',figures:{a:null,b:null},shots:[],winner:null};return;
  }
  const g=state.fold,enemy=other(id);
  check(g&&g.id===data.gameId,'紙張已更新，請重新開啟遊戲');
  check(g.status!=='finished','對局已結束');
  if(action==='fold/surrender'){g.status='finished';g.winner=enemy;g.reason='surrender';return;}
  if(action==='fold/place'){
    check(g.status==='setup'&&!g.figures[id],'已經封好畫紙');
    check(Array.isArray(data.figures)&&data.figures.length===3,'請畫出並放好三個小人');
    const figures=data.figures.map(f=>{
      check(f&&finite(f.x,10,90)&&finite(f.y,10,90),'小人要留在紙張邊界內');
      check(Array.isArray(f.strokes)&&f.strokes.length>0&&f.strokes.length<=20,'請先畫好小人');
      let count=0;
      const strokes=f.strokes.map(line=>{check(Array.isArray(line)&&line.length>=2,'筆畫太短');count+=line.length;check(count<=240,'筆畫過多，請簡化小人');return line.map(p=>{check(Array.isArray(p)&&p.length===2&&finite(p[0],0,40)&&finite(p[1],0,50),'筆畫超出畫框');return [p[0],p[1]];});});
      return {x:f.x,y:f.y,strokes,hit:false};
    });
    check(figures.every((f,i)=>figures.slice(i+1).every(b=>Math.hypot(f.x-b.x,f.y-b.y)>=22)),'小人要相隔至少一個身位');
    g.figures[id]=figures;
    if(g.figures.a&&g.figures.b)g.status='playing';return;
  }
  check(action==='fold/drop'&&g.status==='playing'&&g.turn===id,'還沒輪到你落墨');
  check(data.shotNumber===g.shots.length,'這一滴已處理，請等畫紙展開');
  check(finite(data.x,3,97)&&finite(data.y,3,97),'請在自己的紙上落墨');
  check(!g.shots.some(s=>s.player===id&&Math.hypot(s.x-data.x,s.y-data.y)<4),'這裡已經滴過墨水，換個位置吧');
  const hits=[];
  g.figures[enemy].forEach((f,i)=>{if(!f.hit&&Math.hypot(f.x-(100-data.x),f.y-data.y)<=10){f.hit=true;hits.push(i);}});
  g.shots.push({player:id,x:data.x,y:data.y,hits});g.turn=enemy;
  if(g.figures[enemy].every(f=>f.hit)){
    g.status='finished';g.winner=id;g.reason='completed';state.users[id].coins+=40;state.users[enemy].coins+=25;
  }else if(g.shots.length>=60){
    const a=g.figures.b.filter(f=>f.hit).length,b=g.figures.a.filter(f=>f.hit).length;
    g.status='finished';g.winner=a===b?'draw':a>b?'a':'b';g.reason='limit';
    for(const p of ['a','b'])state.users[p].coins+=g.winner==='draw'?30:g.winner===p?40:25;
  }
}
