const {chromium}=require('playwright');
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
const delay=ms=>new Promise(resolve=>setTimeout(resolve,ms));
async function until(check,message,timeout=60000){
  const end=Date.now()+timeout;
  while(Date.now()<end){if(await check())return;await delay(120);}
  throw new Error(message);
}
(async()=>{
  const {createApp}=await import('../server/server.mjs');
  const root=path.resolve('.runtime');fs.mkdirSync(root,{recursive:true});
  fs.mkdirSync('screenshots',{recursive:true});
  const dir=fs.mkdtempSync(path.join(root,'home-mobile-'));
  const {server,store}=createApp({file:path.join(dir,'state.json'),accessCode:'mobile-test-only'});
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const url=`http://127.0.0.1:${server.address().port}`;
  let browser;
  try{
    browser=await chromium.launch({channel:'chrome',headless:true,args:['--enable-webgl','--ignore-gpu-blocklist','--enable-unsafe-swiftshader']});
    const pages=[],sessions=[],states=[null,null],errors=[];
    for(const [index,id] of ['a','b'].entries()){
      const context=await browser.newContext({viewport:{width:844,height:390},deviceScaleFactor:1,isMobile:true,hasTouch:true});
      const page=await context.newPage();pages.push(page);sessions.push(await context.newCDPSession(page));
      page.on('pageerror',error=>errors.push(error.message));
      page.on('console',message=>{if(message.type()==='error'){errors.push(message.text());console.error(message.text());}});
      page.on('response',async response=>{
        if(response.url().endsWith('/api/home2d')&&response.status()===200&&response.request().frame()!==page.mainFrame()){
          try{states[index]=await response.json();}catch{}
        }
      });
      await page.goto(url);
      await page.locator(`input[value="${id}"]`).check();
      await page.locator('#code').fill('mobile-test-only');await page.locator('#enter').tap();
      await until(()=>page.evaluate(()=>window.homeMobile?.state.connected),'Mobile engine did not connect');
      await until(()=>store.home2dPresence?.[id],`No mobile presence for ${id}`);
    }
    await until(()=>states.every(s=>s?.presence?.a&&s?.presence?.b),'Mobile avatars did not synchronize');
    async function touch(index,dx,dy,milliseconds,cancel=false){
      const rect=await pages[index].locator('#mobile-stick').boundingBox();
      const point={x:rect.x+rect.width/2+dx,y:rect.y+rect.height/2+dy,id:0};
      await sessions[index].send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[point]});
      await delay(milliseconds);
      await sessions[index].send('Input.dispatchTouchEvent',{type:cancel?'touchCancel':'touchEnd',touchPoints:[]});
    }
    const beforeA=store.home2dPresence.a.x;
    await touch(0,-38,0,500,true);
    await until(()=>store.home2dPresence.a.x<beforeA-20,'Player A joystick did not move');
    await delay(600);const stopped=store.home2dPresence.a.x;await delay(600);
    assert.ok(Math.abs(store.home2dPresence.a.x-stopped)<2,'Cancelled touch kept moving');
    const beforeB=store.home2dPresence.b.x;
    await touch(1,38,0,1100);
    await until(()=>store.home2dPresence.b.x>beforeB+25,'Player B joystick did not move');
    await until(()=>pages[1].locator('#mobile-action').isEnabled(),'Nearby mobile interaction unavailable');
    await pages[1].locator('#mobile-action').tap();
    await until(()=>store.state.home2d?.coins>120,'Touch interaction did not apply activity');
    await pages[0].screenshot({path:'screenshots/home-mobile-landscape.png'});
    await pages[0].locator('#mobile-zoom').tap();
    await pages[0].locator('#mobile-menu').tap();
    await pages[0].getByRole('button',{name:'聊天',exact:true}).tap();
    await pages[0].getByLabel('訊息',{exact:true}).fill('手機聊天測試');
    const still=store.home2dPresence.a.x;await delay(600);
    assert.ok(Math.abs(store.home2dPresence.a.x-still)<2,'Opening mobile menu did not stop movement');
    await pages[0].getByRole('button',{name:'送出',exact:true}).tap();
    await until(()=>states.every(s=>s?.messages.some(m=>m.text==='手機聊天測試')),'Mobile chat did not reach both engines');
    await pages[0].screenshot({path:'screenshots/home-mobile-chat.png'});
    await pages[0].locator('#mobile-close').tap();
    await pages[1].locator('#mobile-menu').tap();
    await pages[1].getByRole('button',{name:'日記',exact:true}).tap();
    await pages[1].getByLabel('今天的日記',{exact:true}).fill('兩支手機一起回家');
    await pages[1].getByRole('button',{name:'記下今天',exact:true}).tap();
    await until(()=>states.every(s=>s?.diary.some(m=>m.text==='兩支手機一起回家')),'Mobile diary did not synchronize');
    await pages[1].locator('#mobile-close').tap();
    await pages[0].setViewportSize({width:390,height:844});
    await pages[0].locator('#mobile-portrait').waitFor({state:'visible'});
    await pages[0].screenshot({path:'screenshots/home-mobile-portrait.png'});
    await pages[0].setViewportSize({width:667,height:375});
    await pages[0].locator('#mobile-portrait').waitFor({state:'hidden'});
    await pages[0].locator('#mobile-menu').tap();
    await pages[0].getByRole('button',{name:'約會',exact:true}).tap();
    await pages[0].getByLabel('約會名稱',{exact:true}).fill('週末見面');
    await pages[0].setViewportSize({width:667,height:220});
    await pages[0].getByRole('button',{name:'保存約會',exact:true}).tap();
    await until(()=>store.state.home2d?.date?.title==='週末見面','Short keyboard-sized viewport blocked submit');
    assert.equal(await pages[0].evaluate(()=>document.documentElement.scrollWidth>innerWidth),false,'Mobile page overflows horizontally');
    await pages[0].screenshot({path:'screenshots/home-mobile-keyboard.png'});
    await pages[0].locator('#mobile-close').tap();
    await pages[0].setViewportSize({width:667,height:375});
    await delay(500);await pages[0].screenshot({path:'screenshots/home-mobile-small.png'});
    await pages[1].reload();
    await until(()=>pages[1].evaluate(()=>window.homeMobile?.state.connected),'Mobile reload did not restore session');
    await pages[1].locator('#mobile-menu').tap();await pages[1].getByRole('button',{name:'登出',exact:true}).tap();
    await pages[1].locator('#login-form').waitFor({state:'visible'});
    const desktop=await browser.newContext({viewport:{width:1280,height:800}});
    const computer=await desktop.newPage();
    computer.on('pageerror',error=>errors.push(error.message));
    computer.on('console',message=>{if(message.type()==='error')errors.push(message.text());});
    let desktopState=null;
    computer.on('response',async response=>{
      if(response.url().endsWith('/api/home2d')&&response.status()===200){try{desktopState=await response.json();}catch{}}
    });
    await computer.goto(url);await computer.locator('input[value="b"]').check();
    await computer.locator('#code').fill('mobile-test-only');await computer.locator('#enter').click();
    await until(()=>desktopState?.presence?.a&&desktopState?.id==='b','Desktop did not join the mobile home');
    await pages[0].evaluate(()=>window.homeMobile.openPanel('note'));
    await pages[0].getByLabel('留給彼此的話',{exact:true}).fill('手機和電腦的共同便條');
    await pages[0].getByRole('button',{name:'貼上便條',exact:true}).tap();
    await until(()=>desktopState?.note==='手機和電腦的共同便條','Mobile note did not reach desktop');
    assert.deepEqual(errors,[],'Mobile WebGL or JavaScript errors');
    console.log('PASS: two mobile WebGL clients, real touch joystick, cancellation, interaction, shared chat/diary, modal pause, rotation, small and keyboard-sized viewports, reload/logout, mobile-to-desktop note');
  }finally{
    await browser?.close();server.closeAllConnections();await new Promise(resolve=>server.close(resolve));
    if(path.dirname(dir)===root&&path.basename(dir).startsWith('home-mobile-'))fs.rmSync(dir,{recursive:true});
  }
})().catch(error=>{console.error(error);process.exitCode=1;});
