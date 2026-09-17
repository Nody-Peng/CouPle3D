const {chromium}=require('playwright');
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');

(async()=>{
  const {createApp}=await import('../server/server.mjs');
  const data=path.resolve('.runtime/numberhunt-browser-'+Date.now()+'.json');
  const {server}=createApp({file:data});await new Promise(resolve=>server.listen(8791,'127.0.0.1',resolve));
  let browser;const errors=[];
  try{
    browser=await chromium.launch({channel:'chrome',headless:true,args:['--enable-webgl','--ignore-gpu-blocklist','--enable-unsafe-swiftshader']});
    const contextA=await browser.newContext({viewport:{width:1280,height:820}}),contextB=await browser.newContext({viewport:{width:390,height:844},isMobile:true,hasTouch:true});
    const a=await contextA.newPage(),b=await contextB.newPage();
    for(const page of [a,b]){page.on('pageerror',error=>errors.push(error.message));page.on('console',message=>{if(message.type()==='error'&&!message.text().includes('favicon'))errors.push(message.text());});}
    for(const [page,id] of [[a,'a'],[b,'b']]){await page.goto('http://127.0.0.1:8791');await page.locator(`button[value="${id}"]`).click();await page.locator('#loading').waitFor({state:'hidden',timeout:90000});}
    await a.locator('#menu-toggle').click();await a.getByRole('button',{name:'找數字',exact:true}).click();await a.locator('#number-new').click();
    await b.locator('#menu-toggle').click();await b.getByRole('button',{name:/找數字/}).click();await b.locator('#number-accept').waitFor();await b.locator('#number-accept').click();
    await a.locator('.number-grid').waitFor();await b.locator('.number-grid').waitFor();
    assert.equal(await a.locator('.number-cell').count(),48);assert.equal(await b.locator('.number-cell').count(),48);
    assert.equal(await a.locator('.number-prompt strong').textContent(),await b.locator('.number-prompt strong').textContent());
    await a.screenshot({path:'.runtime/numberhunt-desktop.png'});await b.screenshot({path:'.runtime/numberhunt-mobile.png'});
    for(let score=1;score<=5;score++){
      const target=await a.locator('.number-prompt strong').textContent();await a.locator(`[data-number="${target}"]`).click();
      if(score<5)await a.waitForFunction(expected=>document.querySelector('.number-score div b')?.textContent===String(expected),score);
    }
    await a.locator('.number-result').waitFor();assert.match(await a.locator('.number-result').textContent(),/你先找到五次/);
    assert.deepEqual(errors,[]);console.log('PASS number hunt: invite, shared board, responsive layouts, five-round scoring and result');
    await contextA.close();await contextB.close();
  }finally{if(browser)await browser.close();await new Promise(resolve=>server.close(resolve));if(fs.existsSync(data))fs.rmSync(data,{force:true});}
})().catch(error=>{console.error(error);process.exitCode=1;});
