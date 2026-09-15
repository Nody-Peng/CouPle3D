const {chromium}=require('playwright');
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
(async()=>{
  const {createApp}=await import('../server/server.mjs');
  const data=path.resolve('.runtime/browser-test-'+Date.now()+'.json');
  const {server}=createApp({file:data});await new Promise(r=>server.listen(8790,'127.0.0.1',r));
  const browser=await chromium.launch({channel:'chrome',headless:true,args:['--enable-webgl','--ignore-gpu-blocklist','--enable-unsafe-swiftshader']});
  const errors=[];const contexts=[];
  try {
    const a=await browser.newContext({viewport:{width:1440,height:900}}),b=await browser.newContext({viewport:{width:1280,height:800}});contexts.push(a,b);
    const pa=await a.newPage(),pb=await b.newPage();
    for(const p of [pa,pb]){p.on('pageerror',e=>errors.push(e.message));p.on('console',msg=>{if(msg.type()==='error'&&!msg.text().includes('favicon'))errors.push(msg.text());});}
    await pa.goto('http://127.0.0.1:8790');await pa.screenshot({path:'screenshots/web-login.png'});
    await pa.locator('button[value="a"]').click();await pa.locator('#app').waitFor({state:'visible'});await pa.locator('#loading').waitFor({state:'hidden',timeout:90000});
    await pb.goto('http://127.0.0.1:8790');await pb.locator('button[value="b"]').click();await pb.locator('#app').waitFor({state:'visible'});await pb.locator('#loading').waitFor({state:'hidden',timeout:90000});
    await pa.waitForFunction(()=>document.getElementById('partner-status').textContent.includes('在線'),{timeout:15000});
    await pa.screenshot({path:'screenshots/web-world.png'});
    await pa.getByRole('button',{name:'小商店',exact:true}).click();await pa.locator('[data-buy="hat_beret"]').click();await pa.waitForFunction(()=>document.getElementById('coins').textContent==='70');
    await pa.locator('#close-modal').click();await pa.getByRole('button',{name:'衣櫃',exact:true}).click();await pa.locator('[data-slot="hat"]').selectOption('hat_beret');await pa.locator('#save-avatar').click();
    await pa.waitForFunction(async()=>{const s=await(await fetch('/api/state')).json();return s.user.avatar.hat==='hat_beret';});await pa.screenshot({path:'screenshots/web-wardrobe.png'});
    await pa.locator('#close-modal').click();
    for(const p of [pa,pb]){await p.getByRole('button',{name:'共同銀行',exact:true}).click();await p.locator('#bank-deposit-form input[name="amount"]').fill('60');await p.getByRole('button',{name:'蓋章存入',exact:true}).click();await p.waitForTimeout(400);await p.locator('#close-modal').click();}
    await pa.getByRole('button',{name:'小商店',exact:true}).click();await pa.locator('#wallet').selectOption('shared');await pa.locator('[data-buy="sofa_rose"]').click();await pa.waitForTimeout(500);await pa.locator('#close-modal').click();
    await pb.getByRole('button',{name:'共同銀行',exact:true}).click();await pb.getByRole('button',{name:'提案'}).click();await pb.getByRole('button',{name:'同意並蓋章'}).click();await pb.waitForTimeout(500);await pb.locator('#close-modal').click();
    await pa.getByRole('button',{name:'布置',exact:true}).click();await pa.locator('#start-edit').click();await pa.locator('[data-select]').first().click();
    const svg=pa.locator('#edit-map'),box=await svg.boundingBox();
    // Use the SVG transform, not an assumed CSS pixel-to-world ratio.
    const point=await svg.evaluate(el=>{const p=new DOMPoint(0,12.5).matrixTransform(el.getScreenCTM());return {x:p.x,y:p.y};});
    await pa.mouse.click(point.x,point.y);await pa.locator('#save-layout').click();await pa.waitForTimeout(500);
    const layout=await pa.evaluate(async()=>{const s=await(await fetch('/api/state')).json();return s.home.layout;});assert.equal(layout.length,1);
    await pa.screenshot({path:'screenshots/web-furniture.png'});await pa.locator('#close-modal').click();
    await pa.getByRole('button',{name:'海戰棋',exact:true}).click();await pa.locator('#new-game').click();await pa.locator('#place-ships').click();
    await pb.getByRole('button',{name:'海戰棋',exact:true}).click();await pb.locator('#place-ships').click();await pa.waitForTimeout(400);
    await pb.reload();await pb.locator('#app').waitFor({state:'visible'});await pb.locator('#loading').waitFor({state:'hidden',timeout:90000});await pb.getByRole('button',{name:'海戰棋',exact:true}).click();
    const hits=[0,1,2,12,13,27,33],misses=[5,11,17,23,29,35];
    for(let i=0;i<hits.length;i++){await pa.locator(`[data-fire="${hits[i]}"]:not(:disabled)`).click();if(i<misses.length)await pb.locator(`[data-fire="${misses[i]}"]:not(:disabled)`).click();}
    await pa.waitForFunction(()=>document.getElementById('modal-content').textContent.includes('你贏了'));await pa.screenshot({path:'screenshots/web-battleship.png'});
    await pa.reload();await pa.locator('#app').waitFor({state:'visible'});await pa.locator('#loading').waitFor({state:'hidden',timeout:90000});
    const saved=await pa.evaluate(async()=>await(await fetch('/api/state')).json());assert.equal(saved.user.avatar.hat,'hat_beret');assert.equal(saved.home.layout.length,1);assert.equal(saved.game.status,'finished');
    await pb.close();
    const mobile=await browser.newContext({viewport:{width:844,height:390},isMobile:true,hasTouch:true,deviceScaleFactor:1});contexts.push(mobile);const pm=await mobile.newPage();await pm.goto('http://127.0.0.1:8790');await pm.locator('button[value="b"]').click();await pm.locator('#app').waitFor({state:'visible'});await pm.locator('#loading').waitFor({state:'hidden',timeout:90000});assert.ok(await pm.locator('#touch-pad').isVisible());await pm.screenshot({path:'screenshots/web-mobile.png'});
    await pm.waitForTimeout(700);
    const before=await pa.evaluate(async()=>(await(await fetch('/api/state')).json()).partner.position);
    const padBox=await pm.locator('#touch-pad').boundingBox();
    await pm.mouse.move(padBox.x+padBox.width/2,padBox.y+padBox.height/2);await pm.mouse.down();await pm.mouse.move(padBox.x+padBox.width/2,padBox.y+8);await pm.waitForTimeout(1400);await pm.mouse.up();await pm.waitForTimeout(600);
    const after=await pa.evaluate(async()=>(await(await fetch('/api/state')).json()).partner.position);
    assert.ok(Math.hypot(after.x-before.x,after.z-before.z)>1,'mobile joystick moves the synchronized avatar');
    fs.writeFileSync('.runtime/browser-errors.json',JSON.stringify(errors,null,2));assert.deepEqual(errors,[]);
    console.log('PASS browser: two Godot clients, live presence, purchase, outfit, deposits, shared furniture, complete battleship, reload persistence, mobile layout');
  } finally {fs.writeFileSync('.runtime/browser-errors.json',JSON.stringify(errors,null,2));await browser.close();server.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});



