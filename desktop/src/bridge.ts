import sampleRoutes from './demo-routes.json';
import demoCollection from './demo-collection.json';
import shopItems from './shop.json';
import {invoke,isTauri} from '@tauri-apps/api/core';
import type {Action,Snapshot,Bucket} from './types';
export const native=isTauri();
export const surface=new URLSearchParams(location.search).get('surface')||'main';
function sampleProvider(provider:string,today:Bucket){const now=new Date();const week=new Date(now.getFullYear(),now.getMonth(),now.getDate()-(now.getDay()+6)%7);const key=(d:Date)=>d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0')+'-'+String(d.getDate()).padStart(2,'0');const days:Record<string,number>={};let weekTotal=0;let month=0;const total=today.input+today.output+today.cacheRead+today.cacheWrite;for(let day=1;day<=now.getDate();day++){const date=new Date(now.getFullYear(),now.getMonth(),day);const amount=day===now.getDate()?total:Math.floor(total*(.3+(day*7%9)/12));days[key(date)]=amount;month+=amount;if(date>=week)weekTotal+=amount}return{provider,files:12,today,week:weekTotal,month,days}}
const designCollection=[2006,2012,...demoCollection.collected.filter(id=>![2006,2012,10430,10385].includes(id))].slice(0,148);
export const preview:Snapshot={
 game:{version:2,active:{speciesId:2003,path:[2001,2002,2003],progress:45000000,selected:null,continuing:false,boost:false},stored:null,eggProgress:0,earned:5000000000,spent:0,collected:designCollection,inventory:{rareCandy:2,mint:1},ledger:{},initialized:[],captureLog:designCollection.filter(id=>id!==2003).map((id,index)=>({id:'sample-'+id,speciesId:id,path:(sampleRoutes as Record<string,number[]>)[String(id)]||[id],caughtAt:new Date(Date.now()-(index+1)*60000).toISOString(),status:'sample'})),history:['14:32  파트너와 연결되었습니다.'],settings:{difficulty:1,shopDifficulty:1,motion:true,showPet:false,petTopmost:true,codexRoots:[],claudeRoots:[]}},
 usage:{providers:[sampleProvider('Codex',{input:10400000,output:5200000,cacheRead:3900000,cacheWrite:1300000}),sampleProvider('Claude Code',{input:4200000,output:2100000,cacheRead:1500000,cacheWrite:600000})],warnings:[],updatedAt:new Date().toISOString(),roots:{}},threshold:80357143,choices:[2004,10054,10055],ready:[],shop:shopItems,demo:true,savePath:'브라우저 디자인 미리보기',error:null
};
let previewState=structuredClone(preview);
export const getSnapshot=()=>native?invoke<Snapshot>('get_snapshot'):Promise.resolve(structuredClone(previewState));
export const refresh=()=>native?invoke<Snapshot>('refresh'):getSnapshot();
export async function mutate(action:Action){if(!native&&action.kind==="settings"&&action.settings){previewState.game.settings=action.settings;return structuredClone(previewState)}if(!native)throw Error('브라우저에서는 디자인만 미리 봅니다. 육성·구매·설정 변경은 데스크톱 앱에서 사용할 수 있습니다.');return invoke<Snapshot>('mutate',{action});}
export async function fileAction(kind:'import_save'|'export_save'){if(!native)throw Error('저장 파일 기능은 데스크톱 앱에서 사용할 수 있습니다.');return invoke<Snapshot|boolean|null>(kind);}
export const openMain=()=>native?invoke('open_main'):Promise.resolve();
