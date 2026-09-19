import crypto from 'node:crypto';

export const furniture = [
  {id:'flowers',name:'窗邊花盆',price:25,file:'Plant.png',x:440,y:230},
  {id:'reading',name:'閱讀扶手椅',price:40,file:'SoftChair.png',x:500,y:677},
  {id:'radio',name:'床頭收音機',price:30,file:'Radio.png',x:713,y:704},
  {id:'art',name:'客廳小畫',price:35,file:'Painting_Small.png',x:590,y:145},
  {id:'candle',name:'餐桌燭光',price:20,file:'Candle.png',x:813,y:413}
];
const initial = () => ({coins:120,note:'歡迎回家。今天也很想你。',revision:0,messages:[],rewards:{},owned:[],profiles:{a:{name:'你',status:'',hair:'longhair'},b:{name:'男朋友',status:'',hair:'shorthair'}},invitation:null,diary:[],date:null});
const fail = message => { const error=new Error(message); error.status=400; throw error; };
const text = (value,max) => {
  if(typeof value!=='string'||!value.trim()||value.trim().length>max) fail('文字不可空白或超過長度限制');
  return value.trim();
};

export function homeSnapshot(store,id) {
  const state=store.state.home2d||initial();
  const presence=Object.fromEntries(Object.entries(store.home2dPresence||{}).filter(([,p])=>store.now()-p.at<6000));
  const result={...structuredClone(state),id,presence,catalog:furniture};
  if(result.question && Object.keys(result.question.answers).length<2) result.question.answers=Object.hasOwn(result.question.answers,id)?{[id]:result.question.answers[id]}:{};
  return result;
}

export function homeCommand(store,id,data) {
  store.activeHome();
  if(data.action==='position') {
    if(!Number.isFinite(data.x)||!Number.isFinite(data.y)||data.x<70||data.x>4250||data.y<125||data.y>790) fail('位置不正確');
    store.home2dPresence||={};
    store.home2dPresence[id]={x:data.x,y:data.y,at:store.now()};
    return;
  }
  store.transaction(()=>{
    const s=store.state.home2d??=initial();
    const at=store.now();
    switch(data.action) {
      case 'note':
        if(data.revision!==s.revision) fail('伴侶剛更新了便條，請關閉後重新開啟再編輯');
        s.note=text(data.text,180);s.revision++;break;
      case 'chat':
        s.messages.push({id:crypto.randomUUID(),author:id,text:text(data.text,300),at});
        s.messages=s.messages.slice(-100);break;
      case 'profile':
        s.profiles[id]={name:text(data.name,12),status:String(data.status||'').slice(0,40),hair:id==='a'?'longhair':'shorthair'};break;
      case 'activity': {
        if(!['sofa','table','bed','bath','garden'].includes(data.id)) fail('活動不存在');
        const key=new Date(at).toISOString().slice(0,10)+':'+id+':'+data.id;
        if(!s.rewards[key]){s.coins+=data.id==='garden'?10:5;s.rewards[key]=true;}
        const today=new Date(at).toISOString().slice(0,10);
        s.rewards=Object.fromEntries(Object.entries(s.rewards).filter(([k])=>k.startsWith(today)));
        break;
      }
      case 'purchase': {
        const item=furniture.find(i=>i.id===data.id);
        if(!item)fail('家具不存在');
        if(s.owned.includes(item.id))break;
        if(s.coins<item.price)fail('共同金幣不足');
        s.coins-=item.price;s.owned.push(item.id);break;
      }
      case 'diary':
        s.diary.push({id:crypto.randomUUID(),author:id,text:text(data.text,800),at});s.diary=s.diary.slice(-100);break;
      case 'question':
        if(s.question && Object.keys(s.question.answers).length<2)fail('先完成目前這張卡片');
        s.question={id:crypto.randomUUID(),prompt:['最想一起度過的週末是什麼樣子？','今天有什麼小事讓你開心？','下次見面，最想一起吃什麼？','如果有一天完全不用工作，想和我做什麼？'][crypto.randomInt(4)],answers:{}};break;
      case 'answer':
        if(!s.question||s.question.id!==data.id)fail('卡片已更新');
        if(Object.hasOwn(s.question.answers,id))fail('已經交出答案');
        s.question.answers[id]=text(data.text,180);break;
      case 'date': {
        const title=text(data.title,80),link=String(data.link||'').trim();
        if(link){let url;try{url=new URL(link);}catch{fail('網址格式不正確');}if(!['https:','http:'].includes(url.protocol))fail('請使用 http 或 https 網址');}
        s.date={title,link,author:id,at};break;
      }
      case 'invite':
        if(s.invitation?.status==='pending'&&at-s.invitation.at<60000)fail('還有一張等待回覆的邀請');
        s.invitation={id:crypto.randomUUID(),author:id,status:'pending',at};break;
      case 'respond':
        if(!s.invitation||s.invitation.id!==data.id||s.invitation.author===id||s.invitation.status!=='pending'||at-s.invitation.at>=60000)fail('邀請已失效');
        if(!['accepted','declined'].includes(data.answer))fail('回覆不正確');
        s.invitation.status=data.answer;break;
      default:fail('不支援的操作');
    }
  });
}
