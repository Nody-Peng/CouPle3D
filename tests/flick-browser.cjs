const {chromium}=require('playwright');
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');

(async()=>{
  const {createApp}=await import('../server/server.mjs');
  const data=path.resolve('.runtime/flick-browser-'+Date.now()+'.json');
  const {server}=createApp({file:data});await new Promise(resolve=>server.listen(8793,'127.0.0.1',resolve));
  let browser;const errors=[];
  try{
    browser=await chromium.launch({channel:'chrome',headless:true,args:['--enable-webgl','--ignore-gpu-blocklist','--enable-unsafe-swiftshader']});
    const contextA=await browser.newContext({viewport:{width:1280,height:860}}),contextB=await browser.newContext({viewport:{width:390,height:844},isMobile:true,hasTouch:true});
    const a=await contextA.newPage(),b=await contextB.newPage();
    for(const page of [a,b]){page.on('pageerror',error=>errors.push(error.message));page.on('console',message=>{if(message.type()==='error'&&!message.text().includes('favicon'))errors.push(message.text());});}
    for(const [page,id] of [[a,'a'],[b,'b']]){await page.goto('http://127.0.0.1:8793');await page.locator(`button[value="${id}"]`).click();await page.locator('#loading').waitFor({state:'hidden',timeout:90000});}
    await a.locator('#menu-toggle').click();await a.getByRole('button',{name:'圓片彈射',exact:true}).click();await a.locator('#flick-new').click();
    await b.locator('#menu-toggle').click();await b.getByRole('button',{name:/圓片彈射/}).click();await b.locator('#flick-accept').waitFor();await b.locator('#flick-accept').click();
    await a.locator('#flick-board').waitFor();await b.locator('#flick-board').waitFor();assert.equal(await a.locator('.flick-piece').count(),16);assert.equal(await b.locator('.flick-piece').count(),16);
    await a.screenshot({path:'.runtime/flick-desktop.png'});await b.screenshot({path:'.runtime/flick-mobile.png'});
    const puck=a.locator('[data-flick-puck="a1"]'),box=await puck.boundingBox(),start={x:box.x+box.width/2,y:box.y+box.height/2};
    const dx=266,dy=126,length=Math.hypot(dx,dy),drag=125;await a.mouse.move(start.x,start.y);await a.mouse.down();await a.mouse.move(start.x-dx/length*drag,start.y-dy/length*drag,{steps:8});await a.mouse.up();
    await a.waitForFunction(async()=>{const state=await(await fetch('/api/state')).json();return state.flick?.shots===1;});
    const state=await a.evaluate(async()=>await(await fetch('/api/state')).json());assert.equal(state.flick.turn,'b');assert.equal(state.flick.scores.a,1);assert.deepEqual(errors,[]);
    console.log('PASS flick table: invite, responsive board, pointer drag, server physics, scoring and turn sync');await contextA.close();await contextB.close();
  }finally{if(browser)await browser.close();await new Promise(resolve=>server.close(resolve));if(fs.existsSync(data))fs.rmSync(data,{force:true});}
})().catch(error=>{console.error(error);process.exitCode=1;});
