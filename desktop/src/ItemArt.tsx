import xA from '../../Sources/PokeTokenBar/Resources/Digimon/x-antibody-a.png?inline';
import xS from '../../Sources/PokeTokenBar/Resources/Digimon/x-antibody-s.png?inline';
import {useEffect,useState} from 'react';
import {invoke} from '@tauri-apps/api/core';
import {native} from './bridge';
import {artSources} from './catalog';
import items from './shop.json';
const bundled:Record<string,string>={"x-antibody-a":xA,"x-antibody-s":xS};
const cache=new Map<string,Promise<string>>();
function load(asset:string){if(bundled[asset])return Promise.resolve(bundled[asset]);let p=cache.get(asset);if(!p){p=native?invoke<string>('get_artwork',{asset}):preview(asset);cache.set(asset,p);p.catch(()=>cache.delete(asset));}return p;}
async function preview(asset:string){const source=artSources[asset];if(!source)return '';if(!source.pageImage)return source.url;const html=await(await fetch(source.url)).text();const url=new DOMParser().parseFromString(html,'text/html').querySelector('meta[property="og:image"]')?.getAttribute('content')||'';const parsed=new URL(url);return parsed.protocol==='https:'&&parsed.hostname.endsWith('.wixmp.com')?url:'';}
export function AssetImage({asset,label,className=''}:{asset:string;label:string;className?:string}){const[src,setSrc]=useState('');const[failed,setFailed]=useState(false);useEffect(()=>{let alive=true;setSrc('');setFailed(false);load(asset).then(s=>{if(alive){setSrc(s);setFailed(!s)}}).catch(()=>alive&&setFailed(true));return()=>{alive=false}},[asset]);return <div className={'asset-image '+className}>{src&&!failed?<img src={src} alt={label} onError={()=>setFailed(true)}/>:<span className="item-image-status">{failed?'이미지를 받지 못했어요. 연결을 확인하고 다시 시도해 주세요.':'이미지를 불러오는 중…'}{failed&&artSources[asset]&&<a href={artSources[asset].url} target="_blank" rel="noreferrer">원본 보기 ↗</a>}</span>}</div>}
export function ItemArt({id}:{id:string}){const item=items.find(i=>i.id===id);return item?<AssetImage asset={item.asset} label={item.name} className="item-art"/>:null}