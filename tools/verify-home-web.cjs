const {chromium}=require('playwright');
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
async function until(check,message,timeout=90000){
  const end=Date.now()+timeout;
  while(Date.now()<end){if(await check())return;await new Promise(r=>setTimeout(r,150));}
  throw new Error(message);
}
(async()=>{
  const {createApp}=await import('../server/server.mjs');
  const root=path.resolve('.runtime');
  fs.mkdirSync(root,{recursive:true});
  fs.mkdirSync(path.resolve('screenshots'),{recursive:true});
  const dir=fs.mkdtempSync(path.join(root,'home-web-'));
  const {server,store}=createApp({file:path.join(dir,'state.json'),accessCode:'web-test-only'});
  await new Promise(r=>server.listen(0,'127.0.0.1',r));
  const url=`http://127.0.0.1:${server.address().port}`;
  let browser;
  try{
    browser=await chromium.launch({channel:'chrome',headless:true,args:['--enable-webgl','--ignore-gpu-blocklist','--enable-unsafe-swiftshader']});
    const contexts=[],pages=[],states=[null,null],errors=[];
    for(const [index,id] of ['a','b'].entries()){
      const context=await browser.newContext({viewport:{width:1440,height:900}});
      const page=await context.newPage();contexts.push(context);pages.push(page);
      page.on('pageerror',e=>errors.push(e.message));
      page.on('console',m=>{if(m.type()==='error'&&!m.text().includes('favicon')){errors.push(m.text());console.error(m.text());}});
      page.on('response',async response=>{
        if(response.url().endsWith('/api/home2d')&&response.status()===200){
          try{states[index]=await response.json();}catch{}
        }
      });
      await page.goto(url);
      await page.locator(`input[value="${id}"]`).check();
      await page.locator('#code').fill('web-test-only');
      await page.locator('#enter').click();
      await until(()=>store.home2dPresence?.[id],`Exported Godot client ${id} never published presence`);
      assert.equal(states[index]?.id,id);
    }
    await until(()=>states.every(s=>s?.presence?.a&&s?.presence?.b),'Both clients must receive both avatars');
    for(let i=0;i<2;i++){
      const id=i===0?'a':'b';
      const before=store.home2dPresence[id].x;
      await pages[i].frameLocator('#game').locator('canvas').click({position:{x:720,y:450}});
      await pages[i].keyboard.down('d');
      await new Promise(r=>setTimeout(r,500));
      await pages[i].keyboard.up('d');
      await until(()=>store.home2dPresence[id].x>before+15,`WASD movement failed for ${id}`);
    }
    const a=contexts[0].request,b=contexts[1].request;
    let snapshot=await (await a.get(url+'/api/home2d')).json();
    assert.equal((await a.post(url+'/api/home2d',{data:{action:'note',text:'Browser pair verified',revision:snapshot.revision}})).status(),200);
    await until(()=>states.every(s=>s?.note==='Browser pair verified'),'Note did not reach both running Godot clients');
    assert.equal((await b.post(url+'/api/home2d',{data:{action:'chat',text:'Both browsers connected'}})).status(),200);
    await until(()=>states.every(s=>s?.messages.some(m=>m.text==='Both browsers connected')),'Chat not synchronized');
    await pages[0].screenshot({path:'screenshots/home-web-a.png'});
    await pages[1].screenshot({path:'screenshots/home-web-b.png'});
    states[1]=null;
    await pages[1].reload();
    await until(()=>pages[1].frameLocator('#game').locator('canvas').isVisible().catch(()=>false),'Cookie session did not survive reload');
    await until(()=>states[1]?.id==='b'&&states[1]?.presence?.a,'Reloaded game did not resume its authenticated session');
    await pages[0].setViewportSize({width:960,height:600});
    await new Promise(r=>setTimeout(r,600));
    await pages[0].screenshot({path:'screenshots/home-web-small.png'});
    await pages[0].locator('#logout').click();
    await pages[0].locator('#login-form').waitFor({state:'visible'});
    assert.equal((await a.get(url+'/api/home2d')).status(),401);
    assert.equal((await b.get(url+'/api/home2d')).status(),200);
    assert.deepEqual(errors,[],'WebGL or resource errors');
    console.log('PASS: two exported WebGL clients; isolated cookie sessions; both WASD controls; presence, note/chat synchronization; reload; logout; desktop/small screenshots');
  }finally{
    await browser?.close();server.closeAllConnections();await new Promise(r=>server.close(r));
    if(path.dirname(dir)===root&&path.basename(dir).startsWith('home-web-'))fs.rmSync(dir,{recursive:true});
  }
})().catch(error=>{console.error(error);process.exitCode=1;});
