const {chromium}=require('playwright');
const assert=require('node:assert/strict');
const path=require('node:path');
(async()=>{
 const {createApp}=await import('../server/server.mjs');const {server}=createApp({file:path.resolve('.runtime/expanded-ui-'+Date.now()+'.json')});await new Promise(r=>server.listen(8791,'127.0.0.1',r));
 let browser;const errors=[];
 try{
 browser=await chromium.launch({channel:'chrome',headless:true,args:['--enable-webgl','--ignore-gpu-blocklist','--enable-unsafe-swiftshader']});
 const a=await browser.newContext({viewport:{width:1440,height:900}}),b=await browser.newContext({viewport:{width:1280,height:800}});
 const pa=await a.newPage(),pb=await b.newPage();
 for(const [p,id] of [[pa,'a'],[pb,'b']]){p.on('pageerror',e=>errors.push(e.message));await p.goto('http://127.0.0.1:8791');await p.locator(`button[value="${id}"]`).click();await p.locator('#app').waitFor({state:'visible'});await p.locator('#loading').waitFor({state:'hidden',timeout:90000});}
 await pa.getByRole('button',{name:'衣櫃',exact:true}).click();await pa.locator('#profile-name').fill('花園旅人');await pa.getByRole('button',{name:'更新暱稱',exact:true}).click();await pb.waitForFunction(()=>document.getElementById('partner-status').textContent.includes('花園旅人'));
 assert.equal(await pa.locator('[data-base]').count(),12);await pa.locator('[data-base="female-f"]').click();await pa.locator('#save-avatar').click();await pa.waitForFunction(async()=>(await(await fetch('/api/state')).json()).user.avatar.base==='female-f');await pa.locator('#turn-avatar-right').click();await pa.waitForFunction(()=>Array.from(document.querySelectorAll('.avatar-options img')).every(i=>i.complete&&i.naturalWidth>0));await pa.screenshot({path:'screenshots/upgraded-wardrobe.png'});await pa.locator('#close-modal').click();
 await pa.getByRole('button',{name:'小商店',exact:true}).click();await pa.waitForFunction(()=>Array.from(document.querySelectorAll('.product-art img')).every(i=>i.complete&&i.naturalWidth>0));await pa.screenshot({path:'screenshots/upgraded-shop.png'});await pa.locator('[data-buy="hat_beret"]').click();await pa.waitForFunction(()=>document.getElementById('coins').textContent==='70');await pa.locator('#close-modal').click();
 await pa.getByRole('button',{name:'我的錢包',exact:true}).click();assert.ok(await pa.getByText('購買：莓果貝雷帽').isVisible());await pa.screenshot({path:'screenshots/upgraded-wallet.png'});await pa.locator('#close-modal').click();
 await pa.getByRole('button',{name:'動物手帳',exact:true}).click();await pa.screenshot({path:'screenshots/upgraded-zoo-book.png'});await pa.locator('[data-guide-x]').first().click();await pa.locator('#walk-guide').waitFor({state:'visible'});
 for(const p of [pa,pb])await p.evaluate(()=>window.togetherBridge.activity('trivia','默契問答',''));
 await pa.locator('#quiz-start').click();await pb.waitForSelector('#quiz-form');
 for(const p of [pa,pb]){for(let i=0;i<3;i++)await p.locator(`input[name="answer-${i}"][value="${i}"]`).check();await p.getByRole('button',{name:'保存我的答案'}).click();}
 await pa.locator('.wallet-hero strong').filter({hasText:'3 / 3'}).waitFor();await pa.screenshot({path:'screenshots/upgraded-quiz.png'});await pa.locator('#close-modal').click();
 await pa.evaluate(()=>window.togetherBridge.activity('city_bank','一起銀行',''));await pa.locator('.bank-passbook').waitFor();await pa.locator('#close-modal').click();
 await pa.evaluate(()=>window.togetherBridge.activity('bank_atm','ATM',''));await pa.locator('.wallet-hero').waitFor();await pa.locator('#close-modal').click();
 await pa.evaluate(()=>window.togetherBridge.activity('city_fitting','穿搭鏡',''));await pa.locator('#save-avatar').waitFor();await pa.locator('#close-modal').click();
 await pa.evaluate(()=>window.togetherBridge.activity('city_furniture','家具目錄',''));await pa.locator('[data-buy="sofa_rose"]').waitFor();assert.equal(await pa.locator('[data-buy="hat_beret"]').count(),0);await pa.locator('#close-modal').click();
 await pa.setViewportSize({width:844,height:390});await pa.getByRole('button',{name:'城市導覽',exact:true}).click();await pa.screenshot({path:'screenshots/upgraded-mobile-guide.png'});await pa.locator('#recover-player').click();
 assert.deepEqual(errors,[]);console.log('PASS expanded UI: profile synchronization, rendered previews, purchase ledger, zoo guide, private two-player quiz, mobile navigation and recovery');
 }finally{await browser?.close();server.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});


