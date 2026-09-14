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
    await pa.locator('#bicycle-toggle').click();
    await pa.waitForFunction(()=>document.getElementById('bicycle-toggle').textContent.includes('下車'));
    await pb.waitForFunction(async()=>{const s=await(await fetch('/api/state')).json();return s.partner.position?.riding===true;});
    await pa.screenshot({path:'screenshots/web-bicycle.png'});
    await pa.locator('#bicycle-toggle').click();
    await pb.waitForFunction(async()=>{const s=await(await fetch('/api/state')).json();return s.partner.position?.riding===false;});
    assert.deepEqual(errors,[]);
    console.log('PASS bicycle browser: mount button, dismount, two-client riding presence, no console errors');
  } finally {fs.writeFileSync('.runtime/browser-errors.json',JSON.stringify(errors,null,2));await browser.close();server.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});



