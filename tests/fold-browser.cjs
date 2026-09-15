const {chromium}=require('playwright');
const assert=require('node:assert/strict');
const path=require('node:path');
(async()=>{
 const {createApp}=await import('../server/server.mjs');
 const {server,store}=createApp({file:path.resolve('.runtime/fold-browser-'+Date.now()+'.json')});
 await new Promise(r=>server.listen(8792,'127.0.0.1',r));let browser;
 try{
 browser=await chromium.launch({channel:'chrome',headless:true,args:['--enable-webgl','--ignore-gpu-blocklist','--enable-unsafe-swiftshader']});
 const context=await browser.newContext({viewport:{width:1280,height:720}}),p=await context.newPage(),errors=[];p.on('pageerror',e=>errors.push(e.message));
 await p.goto('http://127.0.0.1:8792');await p.locator('button[value="a"]').click();await p.locator('#loading').waitFor({state:'hidden',timeout:90000});
 await p.locator('[data-view="fold"]').click();await p.locator('#fold-start').click();await p.locator('#fold-ready').waitFor();await p.screenshot({path:'screenshots/fold-setup.png'});
 await p.locator('#fold-ready').click();await p.waitForFunction(()=>state.fold.figures.a!==null);
 const gameId=store.state.fold.id;store.command('b','fold/place',{gameId,figures:store.state.fold.figures.a});
 await p.evaluate(async()=>accept(await(await fetch('/api/state')).json()));
 await p.locator('#close-modal').click();await p.waitForFunction(()=>document.activeElement===document.getElementById('game-frame')&&document.getElementById('game-frame').contentDocument.activeElement.tagName==='CANVAS');
 const start=await p.evaluate(()=>position);await p.keyboard.down('KeyW');await p.waitForTimeout(600);await p.keyboard.up('KeyW');await p.waitForTimeout(500);const end=await p.evaluate(()=>position);assert.ok(Math.hypot(start.x-end.x,start.z-end.z)>.05,'movement resumes after close');
 for(const size of [{width:1280,height:720},{width:800,height:600},{width:390,height:844}]){await p.setViewportSize(size);await p.waitForTimeout(250);const layout=await p.evaluate(()=>{const r=document.getElementById('game-frame').getBoundingClientRect(),n=document.querySelector('.toolbar').getBoundingClientRect();return {bottom:r.bottom,right:r.right,top:r.top,navBottom:n.bottom,w:innerWidth,h:innerHeight,scroll:document.documentElement.scrollWidth};});assert.ok(layout.bottom<=layout.h+1&&layout.right<=layout.w+1&&layout.top>=layout.navBottom&&layout.scroll<=layout.w);}
 await p.setViewportSize({width:1280,height:720});await p.screenshot({path:'screenshots/fairy-world.png'});
 await p.locator('[data-view="fold"]').click();
 if(store.state.fold.turn==='b')store.command('b','fold/drop',{gameId,shotNumber:0,x:5,y:5});
 await p.evaluate(async()=>accept(await(await fetch('/api/state')).json()));await p.waitForTimeout(1900);
 const box=await p.locator('#fold-paper').boundingBox();await p.mouse.click(box.x+box.width*.375,box.y+box.height*.25);
 await p.locator('#fold-drop').click();await p.waitForFunction(()=>state.fold.figures.b[0].hit);
 await p.screenshot({path:'screenshots/fold-animation.png'});await p.waitForTimeout(1900);await p.screenshot({path:'screenshots/fold-playing.png'});
 assert.deepEqual(errors,[]);console.log('PASS: Godot load, drawing setup, close focus, immediate movement, 3 viewport sizes, no page errors');
 }finally{await browser?.close();server.closeAllConnections();server.close();}
})().catch(e=>{console.error(e);process.exit(1);});
