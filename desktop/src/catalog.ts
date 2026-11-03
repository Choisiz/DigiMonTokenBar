import speciesData from '../../Sources/PokeTokenBar/Resources/Digimon/time-stranger.json';
import nameData from '../../Sources/PokeTokenBar/Resources/Digimon/korean-names.json';
import ruleData from '../../Sources/PokeTokenBar/Resources/Digimon/evolution-rules.json';
import infoData from '../../Sources/PokeTokenBar/Resources/Digimon/species-info.json';
import circuit from '../../Sources/PokeTokenBar/Resources/Digimon/circuit.json';
import binary from '../../Sources/PokeTokenBar/Resources/Digimon/card-glyphs.json';
import artworkData from '../../Sources/PokeTokenBar/Resources/Digimon/external-artwork.json';
import type {Species,Rule,Bucket,Game} from './types';
export const species=speciesData.records as Species[];
export const byId=new Map(species.map(s=>[s.id,s]));
export const names=new Map(nameData.records.map(s=>[s.id,s.korean]));
export const info=new Map(infoData.records.map(s=>[s.id,s]));
export const rules=ruleData.rules as Rule[];
export const artSources=artworkData as Record<string,{url:string;pageImage:boolean}>;
export const name=(id:number)=>names.get(id)||byId.get(id)?.name||'#'+id;
export const stages=['유년기 I','유년기 II','성장기','성숙기','완전체','궁극체','초궁극체'];
export const compact=(n:number)=>n>=1e9?(n/1e9).toLocaleString('en',{maximumFractionDigits:2})+'B':n>=1e6?(n/1e6).toLocaleString('en',{maximumFractionDigits:2})+'M':n>=1e3?(n/1e3).toLocaleString('en',{maximumFractionDigits:1})+'K':n.toLocaleString();
export const total=(b:Bucket)=>b.input+b.output+b.cacheRead+b.cacheWrite;
export function next(id:number){return [...new Set([...(byId.get(id)?.next??[]).filter(n=>!ruleData.removedEdges.some(e=>e[0]===id&&e[1]===n)),...ruleData.addedEdges.filter(e=>e[0]===id).map(e=>e[1])])];}
export function rule(from:number,to:number):Rule{return rules.find(r=>r.source===from&&r.target===to)||{source:from,target:to,kind:'normal',ingredients:[]};}
export function missingDescendants(id:number,owned:number[]){const seen=new Set([id]);const pending=[id];while(pending.length){const current=pending.pop()!;for(const n of next(current)){if(rule(current,n).kind!=='normal'||seen.has(n))continue;seen.add(n);if(!owned.includes(n))return true;pending.push(n);}}return false;}
interface Shape{color:string;opacity:number;lineWidth:number;points?:{command:string;x:number;y:number}[];rect?:number[];radius?:number;ellipse?:boolean;fill?:string}
function pattern(data:{width:number;height:number;shapes:Shape[]}){
 const shapes=data.shapes.map(s=>{const attrs=' fill="'+(s.fill||'none')+'" stroke="'+s.color+'" stroke-width="'+s.lineWidth+'" opacity="'+s.opacity+'"';if(s.points)return '<path d="'+s.points.map(p=>p.command==='M'||p.command==='L'?p.command+p.x+' '+p.y:'Z').join(' ')+'"'+attrs+'/>';const r=s.rect!;return s.ellipse?'<ellipse cx="'+(r[0]+r[2]/2)+'" cy="'+(r[1]+r[3]/2)+'" rx="'+r[2]/2+'" ry="'+r[3]/2+'"'+attrs+'/>':'<rect x="'+r[0]+'" y="'+r[1]+'" width="'+r[2]+'" height="'+r[3]+'" rx="'+(s.radius||0)+'"'+attrs+'/>';}).join('');
 return 'url("data:image/svg+xml,'+encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="'+data.width+'" height="'+data.height+'">'+shapes+'</svg>')+'")';
}
export const patternStyle={'--circuit':pattern(circuit as {width:number;height:number;shapes:Shape[]}), '--binary':pattern(binary as {width:number;height:number;shapes:Shape[]})} as React.CSSProperties;

export function canContinueSpecies(game:Game,id:number){const special=new Set([...(game.specialCollected||[]),...(game.captureLog||[]).filter(r=>r.status==='registered').map(r=>r.speciesId)]);return special.has(id)&&game.collected.includes(id)&&game.active?.path[0]!==id&&game.stored?.path[0]!==id&&missingDescendants(id,game.collected)}