'use strict';
const form=document.getElementById('login-form');
const error=document.getElementById('error');
const frame=document.getElementById('game');
const logout=document.getElementById('logout');
function enter(){
  document.getElementById('login').hidden=true;
  frame.hidden=false;
  frame.src='/game/index.html';
  logout.hidden=false;
  frame.onload=()=>frame.contentWindow?.focus();
  window.dispatchEvent(new Event('home:entered'));
}
form.addEventListener('submit',async event=>{
  event.preventDefault();
  const button=document.getElementById('enter');
  button.disabled=true;error.textContent='';
  try{
    const response=await fetch('/api/login',{method:'POST',credentials:'same-origin',headers:{'Content-Type':'application/json'},body:JSON.stringify({id:new FormData(form).get('identity'),code:document.getElementById('code').value})});
    const data=await response.json();
    if(!response.ok)throw new Error(data.error||'登入失敗');
    document.getElementById('code').value='';
    enter();
  }catch(e){error.textContent=e.message;}finally{button.disabled=false;}
});
logout.addEventListener('click',async()=>{
  logout.disabled=true;
  const previous=frame.src;
  frame.src='about:blank';
  try{
    const response=await fetch('/api/logout',{method:'POST',credentials:'same-origin',headers:{'Content-Type':'application/json'},body:'{}'});
    if(!response.ok)throw new Error('登出失敗，請稍後再試');
    location.reload();
  }catch(e){frame.src=previous;logout.textContent=e.message;logout.disabled=false;window.homeMobile?.toast(e.message);}
});
fetch('/api/session',{credentials:'same-origin',cache:'no-store'})
  .then(response=>response.ok?response.json():null)
  .then(session=>{if(session?.user)enter();})
  .catch(()=>{error.textContent='暫時無法連線，請稍後重試。';});
