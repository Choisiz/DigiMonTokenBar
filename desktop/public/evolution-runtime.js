'use strict';
const receiveConfig=event=>{
 if(event.source!==parent||event.data?.channel!=='digimon-evolution-config')return;
 window.removeEventListener('message',receiveConfig);
 const CONFIG=event.data.config;
 document.documentElement.style.setProperty("--scene-circuit",CONFIG.circuit||"none");
 const nonce=CONFIG.bridgeNonce;let sequence=0;
 window.webkit={messageHandlers:{evolution:{postMessage:payload=>new Promise(resolve=>{const request=++sequence;const receive=event=>{if(event.source!==parent||event.data?.channel!=='digimon-evolution-reply'||event.data?.nonce!==nonce||event.data?.request!==request)return;window.removeEventListener('message',receive);resolve(event.data.allowed)};window.addEventListener('message',receive);parent.postMessage({channel:'digimon-evolution',nonce,request,action:payload.action},'*')})}}};
 const fontStyle=document.createElement('style');fontStyle.textContent='@font-face{font-family:"Noto Sans KR";src:url("'+CONFIG.fontUrl+'");font-weight:100 900;font-display:swap}body,button,label,#title,#detail{font-family:"Noto Sans KR",sans-serif}';document.head.append(fontStyle);
'use strict';

const KO={"Digimon evolution animation": "디지몬 진화 연출", "Evolution ready": "진화 준비", "Connect": "연결", "Synchronize": "동기화", "Reconstruct": "재구성", "Reveal": "등장", "Loading artwork…": "이미지 준비 중…", "Reset": "처음으로", "Reduced motion": "간소화", "Collection records are retained. One required item is consumed when evolution starts.": "수집 기록은 유지됩니다. 필요한 아이템은 진화 시작 시 1개 소모됩니다.", "Fusion": "융합", "Evolution": "진화", "Fusion link": "융합 연결", "Connecting the partners’ data circuits.": "두 궁극체의 데이터 회로를 연결합니다.", "Data synchronization": "데이터 동기화", "The partners’ data gathers at the center.": "두 개체의 데이터가 중앙으로 모입니다.", " in progress": " 중", "Reconstructing a new digital life form.": "새로운 디지털 생명체를 구성합니다.", "Evolution complete": "진화 완료", " ready": " 준비", " start": " 시작", " in progress…": " 중…", "Evolution requirements changed. Return Home and check again.": "진화 조건이 변경되었습니다. 홈으로 돌아가 확인해 주세요.", "Artwork could not be loaded. Return Home and retry.": "이미지를 준비하지 못했습니다. 페이지를 새로고침해 주세요.", "Artwork unavailable": "이미지 로드 실패"};
const tr=s=>CONFIG.language==='ko'?(KO[s]??s):s;
document.documentElement.lang=CONFIG.language==='ko'?'ko':'en';

const ART=CONFIG.art;let fusionDone=false,artworkReady=false;function syncEntry(){}
const actionName=CONFIG.kind==='fusion'?tr("Fusion"):tr("Evolution");
const canvas=document.getElementById('scene'), ctx=canvas.getContext('2d');
const start=document.getElementById('start'), reset=document.getElementById('reset'), reduced=document.getElementById('reduced');
const phase=document.getElementById('phase'), title=document.getElementById('title'), detail=document.getElementById('detail'), system=document.getElementById('system');
const steps=[...document.querySelectorAll('.step')];
canvas.setAttribute('aria-label',tr('Digimon evolution animation'));
title.textContent=tr('Evolution ready');
['Connect','Synchronize','Reconstruct','Reveal'].forEach((label,i)=>steps[i].textContent=tr(label));
start.textContent=tr('Loading artwork…');reset.textContent=tr('Reset');
document.querySelector('label').lastChild.textContent=tr('Reduced motion');
document.querySelector('.note').textContent=tr('Collection records are retained. One required item is consumed when evolution starts.');
const W=420,H=365,CYAN='#7dd3fc',GOLD='#ffdf70';
const art={}; let frame=0, began=0, playing=false, current=-2, completed=false, simple=false;
reduced.checked=window.matchMedia('(prefers-reduced-motion: reduce)').matches;
const clamp=x=>Math.max(0,Math.min(1,x)), ease=x=>{x=clamp(x);return x*x*(3-2*x)};
let seed=3197;const random=()=>{seed=(seed*1664525+1013904223)>>>0;return seed/4294967296};
const bits=Array.from({length:220},(_,i)=>({side:i%2,x:random(),y:random(),delay:random()*.22,spin:random()*Math.PI*2,size:1+random()*2.2}));
function line(points,color,alpha=1,width=1){ctx.save();ctx.globalAlpha=alpha;ctx.strokeStyle=color;ctx.lineWidth=width;ctx.beginPath();points.forEach(([x,y],i)=>i?ctx.lineTo(x,y):ctx.moveTo(x,y));ctx.stroke();ctx.restore()}
function text(s,x,y,size=8,color='#6b94ab',align='center',maxWidth=390){ctx.save();ctx.fillStyle=color;ctx.font=`${size}px ui-monospace, monospace`;ctx.textAlign=align;ctx.fillText(s,x,y,maxWidth);ctx.restore()}
function ring(x,y,r,color,alpha=1,angle=0){ctx.save();ctx.globalAlpha=alpha;ctx.strokeStyle=color;ctx.lineWidth=.7;ctx.beginPath();ctx.arc(x,y,r,angle,angle+Math.PI*1.67);ctx.stroke();ctx.setLineDash([1,7]);ctx.beginPath();ctx.arc(x,y,r+7,0,Math.PI*2);ctx.stroke();ctx.restore()}
function portrait(key,x,y,size,opacity=1,silhouette=false){ctx.save();ctx.globalAlpha=opacity;const image=art[key];ctx.drawImage(silhouette?image.shadow:image.cut,x-size/2,y-size/2,size,size);ctx.restore()}
function backdrop(t){ctx.clearRect(0,0,W,H);ctx.fillStyle='#06121a';ctx.fillRect(0,0,W,H);
const glow=ctx.createRadialGradient(210,185,3,210,185,185);glow.addColorStop(0,'#19496935');glow.addColorStop(1,'#06121a00');ctx.fillStyle=glow;ctx.fillRect(0,0,W,H);
for(let i=0;i<7;i++){const y=55+i*43;line([[0,y],[30+(i%3)*18,y],[59+(i%3)*18,y+24],[120,y+24]],CYAN,.09);line([[420,y],[390-(i%3)*18,y],[361-(i%3)*18,y+24],[300,y+24]],CYAN,.09)}
// 128 individual digits: twice the previous 64 characters (32 pairs), same ink color.
for(let i=0;i<128;i++){const col=i%16,row=Math.floor(i/16);const x=24+col*24.8+(row%2)*5,y=45+row*39;text((i*7+row)%3===0?'1':'0',x,y,7,'#28536a')}
line([[18,34],[18,18],[35,18]],CYAN,.6);line([[385,18],[402,18],[402,34]],CYAN,.6);line([[18,330],[18,347],[35,347]],CYAN,.6);line([[385,347],[402,347],[402,330]],CYAN,.6);
text('A / VACCINE',32,46,7,'#9f9062','left');text('B / DATA LINK',388,46,7,'#638ea8','right');text('DNA · 02 → 01',210,334,7,'#4f7c96');}
function updatePhase(index){if(index===current)return;current=index;const data=[['01 / DNA CONNECT',tr("Fusion link"),tr("Connecting the partners’ data circuits.")],['02 / DATA SYNCHRONIZE',tr("Data synchronization"),tr("The partners’ data gathers at the center.")],[CONFIG.kind==='fusion'?'03 / DNA FUSION':'03 / RECONSTRUCTION',actionName+tr(" in progress"),tr("Reconstructing a new digital life form.")],['04 / EVOLUTION COMPLETE',CONFIG.result,tr("Evolution complete")]];
if(index<0){phase.textContent='00 / STANDBY';title.textContent=actionName+tr(" ready");detail.textContent=CONFIG.kind==='normal'?CONFIG.result:CONFIG.left+' + '+CONFIG.right}else{[phase.textContent,title.textContent,detail.textContent]=data[index]}
steps.forEach((s,i)=>{s.classList.toggle('active',i===index);s.classList.toggle('done',i<index)});}
// Three local silhouette dim/return cycles, spaced at 0.5 Hz; no full-screen flashing.
function silhouetteOpacity(t){if(t<2.3)return ease((t-2)/.3);const cycle=clamp((t-2.3)/6)*3;return 1-.82*Math.pow(Math.sin(Math.PI*cycle),2);}
// Project a three-row binary barcode ribbon into a tilted orbit.
// Rear pass precedes the silhouette; foreground pass follows it.
function beltColumn(index,t){const theta=index/96*Math.PI*2+(t-2)*1.65;
const dissolve=ease((t-8.3)/.65),radius=121+55*dissolve,depth=Math.sin(theta);
const x=210+Math.cos(theta)*radius,y=183+depth*33+(x-210)*-.22;
return{theta,depth,x,y:y-dissolve*(10+(index%7)*4),dissolve};}
function dataBelt(t,front){const visibility=ease((t-2)/.35)*(1-ease((t-8.3)/.65));if(visibility<=0)return;
for(let i=0;i<96;i++){const p=beltColumn(i,t);if((p.depth>=0)!==front)continue;
const width=.22+.78*Math.abs(Math.sin(p.theta)),scale=.83+.17*p.depth;
ctx.save();ctx.globalAlpha=visibility*(front?.82:.29);ctx.translate(p.x,p.y);ctx.rotate(-.22);ctx.scale(width,scale);
ctx.fillStyle=i%13===0?GOLD:CYAN;ctx.shadowColor=ctx.fillStyle;ctx.shadowBlur=front?4:0;
ctx.font='7px ui-monospace, monospace';ctx.textAlign='center';
for(let row=0;row<3;row++)ctx.fillText((i*7+row*3)%5<2?'1':'0',0,-8+row*8);
// Barcode separators and upper/lower rails make one continuous belt, rather than loose digits.
ctx.globalAlpha*=.55;ctx.fillRect(3,-15,.6,29);ctx.fillRect(-4,-16,8,.7);ctx.fillRect(-4,15,8,.7);
if(p.dissolve>0){ctx.fillRect((i%3-1)*p.dissolve*15,-23-p.dissolve*20,1.5,1.5)}ctx.restore();}
}
// Reveal lighting stays behind the artwork; no screen-wide flash.
function revealBacklight(t){const age=t-8.3;if(age<0)return;
const fade=ease(age/.28);if(fade<=0)return;
ctx.save();ctx.globalAlpha=fade;
const halo=ctx.createRadialGradient(210,181,16,210,181,157);
halo.addColorStop(0,'#e5f7ff80');halo.addColorStop(.35,'#9cddff50');halo.addColorStop(.7,'#4698c026');halo.addColorStop(1,'#7dd3fc00');
ctx.fillStyle=halo;ctx.fillRect(45,18,330,330);
for(let i=0;i<18;i++){const angle=i/18*Math.PI*2+age*.08,length=116+(i%4)*12,spread=.023+(i%3)*.009;
ctx.save();ctx.translate(210,181);ctx.rotate(angle);const ray=ctx.createLinearGradient(28,0,length,0);ray.addColorStop(0,'#e6f7ff66');ray.addColorStop(.3,i%3===0?'#ffffff50':'#7dd3fc50');ray.addColorStop(1,'#7dd3fc00');ctx.fillStyle=ray;ctx.beginPath();ctx.moveTo(27,-1);ctx.lineTo(length,-length*spread);ctx.lineTo(length,length*spread);ctx.lineTo(27,1);ctx.closePath();ctx.fill();ctx.restore();}
ctx.restore();}
function revealScanlight(reveal){if(reveal<=0||reveal>=1)return;
const y=305-230*reveal;ctx.save();ctx.globalAlpha=Math.sin(reveal*Math.PI)*.7;
const light=ctx.createLinearGradient(0,y-10,0,y+14);light.addColorStop(0,'#7dd3fc00');light.addColorStop(.45,'#dff6ff66');light.addColorStop(.55,'#ffffffaa');light.addColorStop(1,'#7dd3fc00');ctx.fillStyle=light;ctx.fillRect(92,y-10,236,24);ctx.restore();}
function revealGold(t){const age=t-8.3;if(age<.2)return;const fade=ease((age-.2)/.4)*(1-ease((age-1.8)/1.4));if(fade<=0)return;
for(let i=0;i<38;i++){const a=i*2.39996,travel=clamp((age-.2)/(2.1+(i%5)*.1)),radius=86+travel*(25+i%7*7),x=210+Math.cos(a)*radius,y=181+Math.sin(a)*radius*.83-travel*15;
ctx.save();ctx.globalAlpha=fade*(.35+(i%4)*.16);ctx.fillStyle=i%5===0?'#fff5d0':GOLD;ctx.shadowColor=GOLD;ctx.shadowBlur=4;ctx.fillRect(x,y,i%3===0?2:1,2);if(i%9===0){ctx.fillRect(x-2,y+.5,5,.6)}ctx.restore();}}
function draw(ms){if(CONFIG.kind==='normal'&&ms>=0&&!simple)ms+=2000;const t=ms/1000;backdrop(t);
if(simple&&ms>=0){const p=ease(ms/900);ring(210,181,99,CYAN,.4);portrait('omega',210,181,192,p);return}
if(ms<0&&CONFIG.kind==='normal'){portrait('omega',210,181,192,.85,true);text(CONFIG.result,210,304,9,CYAN);return;}if(ms<0||t<.8){const p=ms<0?0:ease(t/.8);ring(104,181,76,GOLD,.3,p);ring(316,181,76,CYAN,.3,-p);portrait('war',104,181,132);portrait('metal',316,181,132);text(CONFIG.left,104,277,9,GOLD,'center',155);text(CONFIG.right,316,277,9,CYAN,'center',155);
line([[174,181],[193,181],[203,171],[217,171],[227,181],[246,181]],CYAN,.25+p*.7);text('×',210,186,16,'#b8ddeb');if(ms>=0){ring(210,181,23,CYAN,p*.5,p*2)}return;}
if(t<2){const p=clamp((t-.8)/1.2);const vanish=1-ease(p*1.7);portrait('war',104,181,132,vanish);portrait('metal',316,181,132,vanish);
for(const bit of bits){const q=ease((p-bit.delay)/(1-bit.delay));const sx=(bit.side?316:104)+(bit.x-.5)*116,sy=181+(bit.y-.5)*140;const orbit=Math.sin(q*Math.PI)*(20+bit.y*50);const x=sx+(210-sx)*q+Math.sin(bit.spin+q*5)*orbit,y=sy+(181-sy)*q+Math.cos(bit.spin+q*5)*orbit;ctx.globalAlpha=Math.sin(Math.PI*clamp(p*1.7))*(1-q*.6);ctx.fillStyle=bit.side?CYAN:GOLD;ctx.fillRect(x,y,bit.size*(1-q*.4),bit.size*(1-q*.4));}ctx.globalAlpha=1;
ring(210,181,82-45*p,CYAN,.3+p*.5,t*2);ring(210,181,92-45*p,GOLD,.25+p*.4,-t*2);text('SYNC '+String(Math.floor(p*100)).padStart(3,'0')+'%',210,294,9,CYAN);return;}
const fusion=ease((t-2)/.3),reveal=ease((t-8.3)/1.05);ring(210,181,104+reveal*7,CYAN,.45*(1-reveal*.5),t*1.2);ring(210,181,117+reveal*9,GOLD,.28*(1-reveal*.5),-t);
if(t<8.3){dataBelt(t,false);ctx.save();ctx.shadowColor=CYAN;ctx.shadowBlur=8+fusion*19;portrait('omega',210,188-7*fusion,170+22*fusion,silhouetteOpacity(t),true);ctx.restore();dataBelt(t,true);line([[133,279-fusion*195],[287,279-fusion*195]],CYAN,.6*Math.sin(fusion*Math.PI));text('RECONSTRUCTING',210,302,8,CYAN)}
else{dataBelt(t,false);revealBacklight(t);portrait('omega',210,181,192+8*Math.sin(reveal*Math.PI),1,true);
ctx.save();ctx.beginPath();ctx.rect(70,305-230*reveal,280,230*reveal);ctx.clip();portrait('omega',210,181,192+8*Math.sin(reveal*Math.PI),1);ctx.restore();
dataBelt(t,true);revealScanlight(reveal);revealGold(t);text(CONFIG.result,210,304,9,CYAN);}

}
function fit(){const dpr=Math.min(window.devicePixelRatio||1,2);canvas.width=W*dpr;canvas.height=H*dpr;ctx.setTransform(dpr,0,0,dpr,0,0)}
function tick(now){const elapsed=Math.min(now-began,simple?900:(CONFIG.kind==='normal'?9500:11500));updatePhase(simple?(elapsed<900?2:3):elapsed+(CONFIG.kind==='normal'?2000:0)<800?0:elapsed+(CONFIG.kind==='normal'?2000:0)<2000?1:elapsed+(CONFIG.kind==='normal'?2000:0)<8300?2:3);draw(elapsed);if(elapsed<(simple?900:(CONFIG.kind==='normal'?9500:11500))){frame=requestAnimationFrame(tick)}else{finish()}}
function finish(){cancelAnimationFrame(frame);frame=0;playing=false;completed=true;fusionDone=true;syncEntry();updatePhase(3);draw(simple?900:(CONFIG.kind==='normal'?9500:11500));system.textContent='DNA LINK / COMPLETE';document.querySelector('.controls').hidden=true;document.querySelector('.note').hidden=true;window.webkit.messageHandlers.evolution.postMessage({action:'done'});}
function standby(){cancelAnimationFrame(frame);frame=0;playing=false;completed=false;simple=false;updatePhase(-1);draw(-1);system.textContent='LOCAL PREVIEW / STANDBY';start.disabled=false;start.textContent=actionName+tr(" start");reset.disabled=false;}
start.addEventListener('click',async()=>{if(playing)return;start.disabled=true;let allowed=false;try{allowed=await window.webkit.messageHandlers.evolution.postMessage({action:'start'})}catch{}if(!allowed){start.disabled=false;detail.textContent=tr("Evolution requirements changed. Return Home and check again.");return;}cancelAnimationFrame(frame);simple=reduced.checked;playing=true;completed=false;began=performance.now();start.disabled=true;start.textContent=actionName+tr(" in progress…");reset.disabled=false;system.textContent='DNA LINK / ACTIVE';frame=requestAnimationFrame(tick)});
reset.addEventListener('click',standby);
document.addEventListener('visibilitychange',()=>{if(document.hidden&&playing)finish()});
window.addEventListener('pagehide',()=>cancelAnimationFrame(frame));
window.addEventListener('resize',()=>{fit();if(!playing)draw(completed?(simple?900:(CONFIG.kind==='normal'?9500:11500)):-1)});
// Display-only border background keying. Original bundled artwork and app resources are never changed.
function prepare(image){const c=document.createElement('canvas');c.width=image.naturalWidth;c.height=image.naturalHeight;const g=c.getContext('2d',{willReadFrequently:true});g.drawImage(image,0,0);const pixels=g.getImageData(0,0,c.width,c.height),d=pixels.data,w=c.width,h=c.height,seen=new Uint8Array(w*h),queue=new Int32Array(w*h);let head=0,tail=0;
function visit(i){if(i<0||i>=w*h||seen[i])return;seen[i]=1;const k=i*4;const lo=Math.min(d[k],d[k+1],d[k+2]),hi=Math.max(d[k],d[k+1],d[k+2]);if(d[k+3]===0||(lo>230&&hi-lo<22)){queue[tail++]=i;d[k+3]=0}}
for(let x=0;x<w;x++){visit(x);visit((h-1)*w+x)}for(let y=0;y<h;y++){visit(y*w);visit(y*w+w-1)}while(head<tail){const i=queue[head++];if(i%w>0)visit(i-1);if(i%w<w-1)visit(i+1);visit(i-w);visit(i+w)}g.putImageData(pixels,0,0);const shadow=document.createElement('canvas');shadow.width=w;shadow.height=h;const sg=shadow.getContext('2d');sg.drawImage(c,0,0);sg.globalCompositeOperation='source-in';sg.fillStyle='#030a12';sg.fillRect(0,0,w,h);return{cut:c,shadow}}
if(CONFIG.kind==='normal'){steps[0].hidden=true;steps[1].hidden=true;document.querySelector('.timeline').style.gridTemplateColumns='repeat(2,1fr)';}
fit();Promise.all(Object.entries(ART).map(([key,src])=>new Promise((resolve,reject)=>{const img=new Image();img.onload=()=>{try{art[key]=prepare(img);resolve()}catch(error){reject(error)}};img.onerror=reject;img.src=src}))).then(()=>{artworkReady=true;syncEntry();standby()}).catch(()=>{system.textContent='ARTWORK LOAD ERROR';detail.textContent=tr("Artwork could not be loaded. Return Home and retry.");detail.classList.add('error');start.textContent=tr("Artwork unavailable");});

};window.addEventListener('message',receiveConfig);parent.postMessage({channel:'digimon-evolution-ready'},'*');