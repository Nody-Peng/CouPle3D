import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {Store,GameError} from './store.mjs';

const ROOT=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
export function createApp(options={}) {
  const storeFile=options.file||process.env.COUPLE_DATA_FILE||path.join(ROOT,'server/data/state.json');
  const store=new Store(storeFile,options);
  const sessions=new Map(),streams=new Set(),limits=new Map();
  const accessCode=options.accessCode||process.env.COUPLE_TEST_CODE||'together-local';
  const reply=(res,status,data)=>{res.writeHead(status,{'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store'});res.end(JSON.stringify(data));};
  const cookie=req=>Object.fromEntries((req.headers.cookie||'').split(';').map(s=>s.trim().split('=')));
  const auth=req=>{const s=sessions.get(cookie(req).couple_session);if(!s||s.expires<Date.now())throw new GameError('請重新登入測試帳號',401);return s.id;};
  const broadcast=()=>{for(const client of streams){client.res.write('data: '+JSON.stringify(store.snapshot(client.id))+'\n\n');}};
  const server=http.createServer(async(req,res)=>{
    try {
      const url=new URL(req.url,'http://local');
      res.setHeader('X-Content-Type-Options','nosniff');res.setHeader('Referrer-Policy','same-origin');
      if(req.method==='POST') {
        if(req.headers.origin && new URL(req.headers.origin).host!==req.headers.host)throw new GameError('來源不符',403);
        if(!req.headers['content-type']?.startsWith('application/json'))throw new GameError('請使用 JSON',415);
        const key=req.socket.remoteAddress,now=Date.now(),rate=limits.get(key)||{time:now,count:0};
        if(now-rate.time>1000){rate.time=now;rate.count=0;}rate.count++;limits.set(key,rate);
        if(rate.count>45)throw new GameError('操作太頻繁',429);
        let raw='';for await(const chunk of req){raw+=chunk;if(Buffer.byteLength(raw)>16000)throw new GameError('請求過大',413);}
        let data;try{data=JSON.parse(raw||'{}');}catch{throw new GameError('JSON 格式錯誤');}
        if(!data||typeof data!=='object'||Array.isArray(data))throw new GameError('請求格式錯誤');
        if(url.pathname==='/api/login') {
          if(!['a','b'].includes(data.id)||data.code!==accessCode)throw new GameError('測試代碼不正確',401);
          const token=crypto.randomBytes(32).toString('hex');sessions.set(token,{id:data.id,expires:now+86400000});
          const secure=req.socket.encrypted||req.headers['x-forwarded-proto']==='https';
          res.setHeader('Set-Cookie',`couple_session=${token}; HttpOnly; SameSite=Strict; Path=/; Max-Age=86400${secure?'; Secure':''}`);
          return reply(res,200,store.snapshot(data.id));
        }
        const id=auth(req);
        if(url.pathname==='/api/logout') {const token=cookie(req).couple_session;sessions.delete(token);res.setHeader('Set-Cookie','couple_session=; HttpOnly; SameSite=Strict; Path=/; Max-Age=0');return reply(res,200,{ok:true});}
        if(!url.pathname.startsWith('/api/'))throw new GameError('找不到路徑',404);
        store.command(id,url.pathname.slice(5),data);
        broadcast();return reply(res,200,store.snapshot(id));
      }
      if(url.pathname==='/api/session') {
        const session=sessions.get(cookie(req).couple_session);
        return reply(res,200,session&&session.expires>=Date.now()?store.snapshot(session.id):{authenticated:false});
      }
      if(url.pathname==='/api/state')return reply(res,200,store.snapshot(auth(req)));
      if(url.pathname==='/api/events') {
        const id=auth(req);res.writeHead(200,{'Content-Type':'text/event-stream','Cache-Control':'no-cache','Connection':'keep-alive'});
        const client={id,res};streams.add(client);res.write('data: '+JSON.stringify(store.snapshot(id))+'\n\n');req.on('close',()=>streams.delete(client));return;
      }
      if(url.pathname==='/api/health')return reply(res,200,{ok:true,mode:'v1',dataFile:path.basename(storeFile)});
      if(req.method!=='GET'&&req.method!=='HEAD')throw new GameError('不支援的方法',405);
      const web=path.join(ROOT,'web');let file=path.resolve(web,'.'+decodeURIComponent(url.pathname==='/'?'/index.html':url.pathname));
      if(!file.startsWith(web+path.sep)||!fs.existsSync(file)||!fs.statSync(file).isFile())throw new GameError('找不到檔案',404);
      const types={'.html':'text/html; charset=utf-8','.css':'text/css','.js':'application/javascript','.json':'application/json','.wasm':'application/wasm','.pck':'application/octet-stream','.png':'image/png','.svg':'image/svg+xml','.woff2':'font/woff2'};
      res.setHeader('Content-Type',types[path.extname(file)]||'application/octet-stream');
      res.setHeader('Cache-Control','no-cache');
      if(req.headers['accept-encoding']?.includes('gzip')&&fs.existsSync(file+'.gz')){file+='.gz';res.setHeader('Content-Encoding','gzip');res.setHeader('Vary','Accept-Encoding');}
      res.setHeader('Content-Length',fs.statSync(file).size);res.writeHead(200);if(req.method==='HEAD')res.end();else fs.createReadStream(file).pipe(res);
    } catch(e){if(!res.headersSent)reply(res,e.status||500,{error:e instanceof GameError?e.message:'伺服器暫時無法完成操作'});else res.end();if(!(e instanceof GameError))console.error(e);}
  });
  const timer=setInterval(()=>{for(const client of streams)client.res.write(': heartbeat\n\n');broadcast();},5000);timer.unref();
  server.on('close',()=>{clearInterval(timer);for(const c of streams)c.res.end();});
  return {server,store};
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  const {server}=createApp();const port=Number(process.env.PORT||8787),host=process.env.HOST||'127.0.0.1';
  server.listen(port,host,()=>console.log(`Together City: http://${host}:${port}  (two test accounts; data persisted locally)`));
}
