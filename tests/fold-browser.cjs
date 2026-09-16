const {chromium}=require('playwright');
const assert=require('node:assert/strict');
const path=require('node:path');
(async()=>{
 const {createApp}=await import('../server/server.mjs');
 const {server}=createApp({file:path.resolve('.runtime/fold-browser-'+Date.now()+'.json')});
 await new Promise(r=>server.listen(8792,'127.0.0.1',r));let browser;
 try{
  browser=await chromium.launch({channel:'chrome',headless:true,args:['--enable-webgl','--ignore-gpu-blocklist','--enable-unsafe-swiftshader']});
  const a=await browser.newContext({viewport:{width:1280,height:800}}),b=await browser.newContext({viewport:{width:1280,height:800}});
  const pa=await a.newPage(),pb=await b.newPage(),errors=[];
  for(const p of [pa,pb])p.on('pageerror',e=>errors.push(e.message));
  for(const [p,id] of [[pa,'a'],[pb,'b']]){
   await p.goto('http://127.0.0.1:8792');await p.locator(`button[value="${id}"]`).click();await p.locator('#loading').waitFor({state:'hidden',timeout:90000});
  }
  await pa.locator('#menu-toggle').click();await pa.locator('[data-view="fold"]').click();await pa.locator('#fold-start').click();
  await pb.locator('#menu-toggle').click();await pb.locator('[data-view="fold"]').click();await pb.locator('#fold-ready').waitFor();
  await pa.screenshot({path:'.runtime/fold-v2-setup.png'});
  for(const p of [pa,pb])await p.locator('#fold-ready').click();
  for(const p of [pa,pb])await p.waitForFunction(()=>state.fold.status==='playing');
  const dimensions=await pa.locator('#fold-paper').evaluate(svg=>({box:svg.getAttribute('viewBox'),width:svg.getBoundingClientRect().width,patterns:svg.querySelectorAll('pattern').length,fill:svg.querySelector('rect').getAttribute('fill'),circles:svg.querySelectorAll('circle').length}));
  assert.equal(dimensions.box,'0 0 320 110');assert.equal(dimensions.patterns,0);assert.equal(dimensions.fill,'#fff');assert.equal(dimensions.circles,0);assert.ok(dimensions.width>1100);
  await pa.locator('#close-modal').click();
  await pa.waitForFunction(()=>document.activeElement===document.getElementById('game-frame')&&document.getElementById('game-frame').contentDocument.activeElement.tagName==='CANVAS');
  const start=await pa.evaluate(()=>position);await pa.keyboard.down('KeyW');await pa.waitForTimeout(600);await pa.keyboard.up('KeyW');await pa.waitForTimeout(500);const end=await pa.evaluate(()=>position);assert.ok(Math.hypot(start.x-end.x,start.z-end.z)>.05);
  await pa.locator('#menu-toggle').click();await pa.locator('[data-view="fold"]').click();
  for(const size of [{width:1280,height:720},{width:800,height:600},{width:390,height:844}]){
   await pa.setViewportSize(size);await pa.waitForTimeout(250);
   const layout=await pa.evaluate(()=>{const paper=document.getElementById('fold-paper').getBoundingClientRect(),modal=document.getElementById('modal');return {left:paper.left,right:paper.right,w:innerWidth,scroll:modal.scrollWidth,client:modal.clientWidth};});
   assert.ok(layout.left>=0&&layout.right<=layout.w&&layout.scroll<=layout.client+1);
  }
  await pa.screenshot({path:'.runtime/fold-v2-mobile.png'});
  await pa.setViewportSize({width:1280,height:800});
  const select=async(p,index)=>{
   await p.locator('#fold-paper').scrollIntoViewIfNeeded();
   const point=await p.evaluate(index=>{const svg=document.getElementById('fold-paper'),f=state.fold.figures[state.user.id==='a'?'b':'a'][index];const p=new DOMPoint(state.fold.rules.width-f.x,f.y).matrixTransform(svg.getScreenCTM());return {x:p.x,y:p.y};},index);
   await p.mouse.click(point.x,point.y);await p.locator('#fold-drop').click();
  };
  for(let round=1;round<=3;round++){
   const [first,second]=round===2?[pb,pa]:[pa,pb];
   await select(first,round-1);await first.waitForFunction(()=>!!state.fold.ownPending);
   await second.waitForFunction(()=>state.fold.partnerReady);
   const hidden=await second.evaluate(async()=>{const g=(await(await fetch('/api/state')).json()).fold;return {pending:g.pending,own:g.ownPending,shots:g.shots.length,round:g.round};});
   assert.equal(hidden.pending,undefined);assert.equal(hidden.own,null);assert.equal(hidden.shots,(round-1)*2);assert.equal(hidden.round,round);
   assert.equal(await first.locator('#fold-drop').count(),0);
   if(round===1){
    await first.reload();await first.locator('#loading').waitFor({state:'hidden',timeout:90000});await first.locator('#menu-toggle').click();await first.locator('[data-view="fold"]').click();
    assert.ok(await first.evaluate(()=>!!state.fold.ownPending));assert.equal(await first.locator('#fold-drop').count(),0);
   }
   await select(second,round-1);
   for(const p of [pa,pb])await p.waitForFunction(count=>state.fold.shots.length===count,round*2);
   await pa.locator('.fold-leaf').first().waitFor({state:'detached',timeout:10000});
   await pb.locator('.fold-leaf').first().waitFor({state:'detached',timeout:10000});
  }
  for(const p of [pa,pb]){
   assert.equal(await p.evaluate(()=>state.fold.winner),'draw');assert.equal(await p.locator('#coins').textContent(),'150');
   await p.locator('#fold-again').waitFor();
  }
  await pa.screenshot({path:'.runtime/fold-v2-draw.png'});
  assert.deepEqual(errors,[]);console.log('PASS: two browser sessions, larger white paper, no grids or aim rings, three viewports, focus/movement, secret shots, reconnect, double lethal draw, 150 coins each, no page errors');
 }finally{await browser?.close();server.closeAllConnections();server.close();}
})().catch(e=>{console.error(e);process.exit(1);});
