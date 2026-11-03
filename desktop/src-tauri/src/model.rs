use std::collections::{BTreeMap,BTreeSet};
use serde::{Serialize,Deserialize};
use rand::seq::SliceRandom;
use chrono::Local;

#[derive(Clone,Serialize,Deserialize,Debug)]
#[serde(rename_all="camelCase")]
pub struct Species { pub id:u32, #[serde(rename="gameID")] pub game_id:u32, pub name:String, pub stage:u8, pub generation:String, pub next:Vec<u32> }
#[derive(Clone,Serialize,Deserialize,Debug)]
#[serde(rename_all="camelCase")]
pub struct Rule { pub source:u32,pub target:u32,pub kind:String,#[serde(default)]pub ingredients:Vec<u32>,pub item:Option<String>,pub daily_tokens:Option<u64> }
#[derive(Deserialize)]
struct Records<T>{records:Vec<T>}
#[derive(Deserialize)]
#[serde(rename_all="camelCase")]
struct Rules{rules:Vec<Rule>,#[serde(default)]removed_edges:Vec<[u32;2]>,#[serde(default)]added_edges:Vec<[u32;2]>}
#[derive(Clone)]
pub struct Catalog{pub species:BTreeMap<u32,Species>,pub names:BTreeMap<u32,String>,pub rules:Vec<Rule>,removed:Vec<[u32;2]>,added:Vec<[u32;2]>}
impl Catalog{
 pub fn load()->Self{
  let data:Records<Species>=serde_json::from_str(include_str!("../../../Sources/PokeTokenBar/Resources/Digimon/time-stranger.json")).expect("bundled species");
  let rules:Rules=serde_json::from_str(include_str!("../../../Sources/PokeTokenBar/Resources/Digimon/evolution-rules.json")).expect("bundled rules");
  #[derive(Deserialize)]struct Name{id:u32,korean:String}
  let names:Records<Name>=serde_json::from_str(include_str!("../../../Sources/PokeTokenBar/Resources/Digimon/korean-names.json")).expect("bundled names");
  Self{species:data.records.into_iter().map(|s|(s.id,s)).collect(),names:names.records.into_iter().map(|s|(s.id,s.korean)).collect(),rules:rules.rules,removed:rules.removed_edges,added:rules.added_edges}
 }
 pub fn next(&self,id:u32)->Vec<u32>{let mut result=self.species.get(&id).map(|s|s.next.clone()).unwrap_or_default();result.retain(|n|!self.removed.contains(&[id,*n]));result.extend(self.added.iter().filter(|e|e[0]==id).map(|e|e[1]));result.sort_unstable();result.dedup();result}
 pub fn normal(&self,from:u32,to:u32)->bool{self.rules.iter().find(|r|r.source==from&&r.target==to).map(|r|r.kind=="normal").unwrap_or(true)}
 pub fn missing(&self,id:u32,owned:&BTreeSet<u32>,visited:&[u32])->bool{let mut seen:BTreeSet<_>=visited.iter().copied().collect();seen.insert(id);let mut pending=vec![id];while let Some(n)=pending.pop(){for next in self.next(n){if self.normal(n,next)&&seen.insert(next){if !owned.contains(&next){return true}pending.push(next)}}}false}
 pub fn name(&self,id:u32)->String{self.names.get(&id).cloned().unwrap_or_else(||format!("#{id}"))}
}
#[derive(Clone,Serialize,Deserialize,Debug,Default)]
#[serde(rename_all="camelCase")]
pub struct Partner{pub species_id:u32,pub path:Vec<u32>,pub progress:u64,pub selected:Option<u32>,#[serde(default)]pub continuing:bool,#[serde(default)]pub boost:bool,#[serde(default)]pub started_at:Option<String>}
#[derive(Clone,Serialize,Deserialize,Debug)]
#[serde(rename_all="camelCase")]
pub struct CaptureRecord{pub id:String,pub species_id:u32,pub path:Vec<u32>,pub caught_at:Option<String>,pub status:String}
#[derive(Clone,Serialize,Deserialize,Debug)]
#[serde(rename_all="camelCase")]
#[serde(default)]
pub struct Settings{pub language:String,pub representative_id:Option<u32>,pub refresh_interval:u64,pub animation_quality:String,pub limit_display_mode:String,pub difficulty:f64,pub shop_difficulty:f64,pub motion:bool,pub show_pet:bool,pub pet_topmost:bool,pub codex_roots:Vec<String>,pub claude_roots:Vec<String>}
impl Default for Settings{fn default()->Self{Self{language:"ko".into(),representative_id:None,refresh_interval:60,animation_quality:"balanced".into(),limit_display_mode:"used".into(),difficulty:1.,shop_difficulty:1.,motion:true,show_pet:false,pet_topmost:true,codex_roots:vec![],claude_roots:vec![]}}}
#[derive(Clone,Serialize,Deserialize,Debug)]
#[serde(rename_all="camelCase")]
pub struct Game{pub version:u32,pub active:Option<Partner>,pub stored:Option<Partner>,pub egg_progress:u64,pub earned:u64,pub spent:u64,pub collected:BTreeSet<u32>,#[serde(default)]pub special_collected:BTreeSet<u32>,pub inventory:BTreeMap<String,u32>,pub ledger:BTreeMap<String,u64>,pub initialized:BTreeSet<String>,pub history:Vec<String>,#[serde(default)]pub capture_log:Vec<CaptureRecord>,pub settings:Settings}
impl Default for Game{fn default()->Self{Self{version:2,active:None,stored:None,egg_progress:0,earned:0,spent:0,collected:BTreeSet::new(),special_collected:BTreeSet::new(),inventory:BTreeMap::new(),ledger:BTreeMap::new(),initialized:BTreeSet::new(),history:vec![],capture_log:vec![],settings:Settings::default()}}}
#[derive(Clone,Serialize,Deserialize,Debug)]
#[serde(rename_all="camelCase")]
pub struct Item{pub id:String,pub name:String,pub price:u64,pub description:String}
pub fn shop()->Vec<Item>{serde_json::from_str(include_str!("../../src/shop.json")).expect("bundled shop catalog")}
impl Game{
 pub fn demo()->Self{let mut s=Self::default();s.active=Some(Partner{species_id:2003,path:vec![2001,2002,2003],progress:45_000_000,..Default::default()});s.earned=760_000_000;s.collected=[2001,2002,2003,2006,2012].into_iter().collect();s.inventory.insert("rareCandy".into(),2);s.inventory.insert("mint".into(),1);s}
 pub fn demo_collection()->Self{let mut game=Self::demo();game.earned=5_000_000_000;let data:serde_json::Value=serde_json::from_str(include_str!("../../src/demo-collection.json")).expect("bundled preview collection");game.collected=data["collected"].as_array().expect("preview ids").iter().map(|id|id.as_u64().expect("species id")as u32).collect();let sample_routes:serde_json::Value=serde_json::from_str(include_str!("../../src/demo-routes.json")).expect("sample routes");for(index,id)in game.collected.iter().filter(|id|**id!=2003).enumerate(){game.capture_log.push(CaptureRecord{id:format!("sample-{id}"),species_id:*id,path:sample_routes[id.to_string()].as_array().map(|route|route.iter().filter_map(|id|id.as_u64().map(|id|id as u32)).collect()).unwrap_or_else(||vec![*id]),caught_at:Some((Local::now()-chrono::Duration::minutes(index as i64+1)).to_rfc3339()),status:"sample".into()})}if let Some(p)=&mut game.active{p.started_at=Some(Local::now().to_rfc3339())}game}
 pub fn is_special_collected(&self,id:u32)->bool{self.special_collected.contains(&id)||self.capture_log.iter().any(|r|r.status=="registered"&&r.species_id==id)}
 pub fn validate(&self,c:&Catalog)->Result<(),String>{
  const MAX:u64=1_000_000_000_000_000;
  if !["ko","en"].contains(&self.settings.language.as_str())||![0,60,120,300,900].contains(&self.settings.refresh_interval)||!["powerSaver","balanced","smooth"].contains(&self.settings.animation_quality.as_str())||!["used","remaining"].contains(&self.settings.limit_display_mode.as_str())||self.settings.representative_id.is_some_and(|id|!self.collected.contains(&id)){return Err("지원하지 않는 설정 값입니다.".into())}if self.version!=2||self.spent>self.earned||self.earned>MAX||self.egg_progress>MAX||!self.settings.difficulty.is_finite()||!(0.1..=2.).contains(&self.settings.difficulty)||!self.settings.shop_difficulty.is_finite()||!(0.1..=2.).contains(&self.settings.shop_difficulty)||self.history.len()>100||self.capture_log.len()>10_000||self.ledger.len()>100_000{return Err("지원하지 않거나 손상된 저장 파일입니다.".into())}
  if !self.special_collected.is_subset(&self.collected){return Err("특수 진화 기록이 올바르지 않습니다.".into())}if self.collected.iter().any(|n|!c.species.contains_key(n))||self.inventory.iter().any(|(k,v)|*v>999||!shop().iter().any(|i|i.id==*k))||self.ledger.values().any(|n|*n>MAX){return Err("도감 또는 토큰 데이터가 올바르지 않습니다.".into())}
  for p in [&self.active,&self.stored].into_iter().flatten(){if p.path.is_empty()||p.path.len()>c.species.len()||p.path.last()!=Some(&p.species_id)||!self.collected.contains(&p.species_id)||p.path.iter().any(|n|!c.species.contains_key(n))||p.path.iter().collect::<BTreeSet<_>>().len()!=p.path.len()||p.progress>MAX{return Err("파트너 데이터가 올바르지 않습니다.".into())}if let Some(n)=p.selected{if !c.next(p.species_id).contains(&n)||p.path.contains(&n)||!c.normal(p.species_id,n){return Err("진화 선택 데이터가 올바르지 않습니다.".into())}}}
  if self.capture_log.iter().any(|r|r.id.is_empty()||!c.species.contains_key(&r.species_id)||r.path.is_empty()||r.path.len()>c.species.len()||r.path.last()!=Some(&r.species_id)||r.path.iter().any(|id|!c.species.contains_key(id))||r.caught_at.as_ref().is_some_and(|s|chrono::DateTime::parse_from_rfc3339(s).is_err())){return Err("포획 기록이 올바르지 않습니다.".into())}
  for paths in [&self.settings.codex_roots,&self.settings.claude_roots]{if paths.len()>20||paths.iter().any(|p|!std::path::Path::new(p).is_absolute()){return Err("로그 경로가 올바르지 않습니다.".into())}}
  Ok(())
 }
 pub fn threshold(&self,c:&Catalog)->u64{let base=if let Some(p)=&self.active{(750_000_000.*(c.species[&p.species_id].stage as f64+1.)/28./if p.boost{2.}else{1.}).round()}else{5_000_000.};(base*self.settings.difficulty).round().max(1.) as u64}
 pub fn progress(&self)->u64{self.active.as_ref().map(|p|p.progress).unwrap_or(self.egg_progress)}
 pub fn choices(&self,c:&Catalog)->Vec<u32>{self.active.as_ref().map(|p|c.next(p.species_id).into_iter().filter(|n|!p.path.contains(n)&&c.normal(p.species_id,*n)&&(!p.continuing||!self.collected.contains(n)||c.missing(*n,&self.collected,&p.path))).collect()).unwrap_or_default()}
 fn log(&mut self,message:String){self.history.insert(0,format!("{}  {}",Local::now().format("%m.%d %H:%M"),message));self.history.truncate(100)}
 fn register(&mut self,id:u32,c:&Catalog,kind:&str){self.collected.insert(id);self.log(format!("{} · {}",kind,c.name(id)))}
 fn advance(&mut self,id:u32,cost:u64,c:&Catalog){if let Some(p)=&mut self.active{p.species_id=id;p.path.push(id);p.progress=p.progress.saturating_sub(cost);p.selected=None;}self.register(id,c,"진화")}
 fn record_partner(&mut self,p:&Partner,status:&str){self.special_collected.extend(self.capture_log.iter().filter(|r|r.status=="registered").map(|r|r.species_id));let now=Local::now();self.capture_log.insert(0,CaptureRecord{id:format!("{}-{}-{}",now.timestamp_micros(),self.capture_log.len(),p.species_id),species_id:p.species_id,path:p.path.clone(),caught_at:Some(now.to_rfc3339()),status:status.into()});self.capture_log.truncate(10_000)}
 fn graduate(&mut self,c:&Catalog){if let Some(p)=self.active.clone(){self.record_partner(&p,"graduated");self.log(format!("{} 육성 완료",c.name(p.species_id)))}self.active=self.stored.take();self.egg_progress=0}
 pub fn grow(&mut self,amount:u64,c:&Catalog){
  if let Some(p)=&mut self.active{p.progress=p.progress.saturating_add(amount)}else{self.egg_progress=self.egg_progress.saturating_add(amount);let threshold=self.threshold(c);if self.egg_progress<threshold{return}let roots:Vec<_>=c.species.values().filter(|s|s.stage==0).collect();let root=roots.choose(&mut rand::thread_rng()).expect("roots").id;self.active=Some(Partner{species_id:root,path:vec![root],started_at:Some(Local::now().to_rfc3339()),progress:self.egg_progress-threshold,boost:self.collected.contains(&root),..Default::default()});self.egg_progress=0;self.register(root,c,"부화")}
  for _ in 0..=c.species.len(){let Some(p)=self.active.as_ref()else{break};let cost=self.threshold(c);if p.progress<cost{break}if p.continuing&&!c.missing(p.species_id,&self.collected,&p.path){self.graduate(c);break}let choices=self.choices(c);if choices.is_empty(){self.graduate(c);break}let fresh:Vec<_>=choices.iter().copied().filter(|n|!self.collected.contains(n)).collect();let pool=if fresh.is_empty(){&choices}else{&fresh};let target=p.selected.filter(|n|choices.contains(n)).unwrap_or(*pool.choose(&mut rand::thread_rng()).unwrap());let cost=if p.continuing&&self.collected.contains(&target){0}else{cost};self.advance(target,cost,c)}
 }
 pub fn observe(&mut self,provider:&str,day:&str,total:u64,c:&Catalog){let key=format!("{provider}:{day}");if self.initialized.insert(provider.into()){self.ledger.insert(key,total);return}let previous=*self.ledger.get(&key).unwrap_or(&0);if total<=previous{return}self.ledger.insert(key,total);let delta=(total-previous).min(1_000_000_000_000_000-self.earned);self.earned+=delta;self.grow(delta,c)}
 pub fn eligible(&self,r:&Rule,today:u64)->bool{match r.kind.as_str(){"fusion"=>!r.ingredients.is_empty()&&r.ingredients.iter().all(|n|self.collected.contains(n)),"item"=>self.collected.contains(&r.source)&&r.item.as_ref().map(|i|self.inventory.get(i).copied().unwrap_or(0)>0).unwrap_or(false),"buff"=>self.collected.contains(&r.source)&&r.daily_tokens.map(|n|n>0&&today>=n).unwrap_or(false),_=>false}}
 pub fn price(&self,item:&Item)->u64{(item.price as f64*self.settings.shop_difficulty).round()as u64}
 pub fn select(&mut self,id:u32,c:&Catalog)->Result<(),String>{if !self.choices(c).contains(&id){return Err("선택할 수 없는 진화입니다.".into())}if self.collected.contains(&id){self.advance(id,0,c)}else{self.active.as_mut().unwrap().selected=Some(id)}self.grow(0,c);Ok(())}
 pub fn special(&mut self,target:u32,today:u64,c:&Catalog)->Result<(),String>{if self.collected.contains(&target){return Err("이미 등록한 디지몬입니다.".into())}let r=c.rules.iter().find(|r|r.target==target&&self.eligible(r,today)).ok_or("진화 조건을 충족하지 못했습니다.")?;if r.kind=="item"{*self.inventory.get_mut(r.item.as_ref().unwrap()).unwrap()-=1}self.special_collected.insert(target);self.register(target,c,"특수 진화");self.record_partner(&Partner{species_id:target,path:vec![target],..Default::default()},"registered");Ok(())}
 pub fn buy_egg(&mut self,c:&Catalog)->Result<(),String>{let price=(1_000_000_000f64*self.settings.shop_difficulty).round()as u64;if self.active.is_none(){return Err("지금 품고 있는 알이 부화하면 살 수 있어요.".into())}if self.earned-self.spent<price{return Err("사용 가능한 토큰이 부족합니다.".into())}let partner=self.active.take().unwrap();self.record_partner(&partner,"released");self.spent+=price;self.egg_progress=0;self.log(format!("{}을(를) 놓아주고 새 디지몬 알을 받았습니다.",c.name(partner.species_id)));Ok(())}
 pub fn buy(&mut self,id:&str)->Result<(),String>{self.buy_count(id,1)}
 pub fn buy_count(&mut self,id:&str,count:u32)->Result<(),String>{let item=shop().into_iter().find(|i|i.id==id).ok_or("존재하지 않는 아이템입니다.")?;let total=self.price(&item).checked_mul(count as u64).ok_or("수량이 너무 큽니다.")?;let owned=*self.inventory.get(id).unwrap_or(&0);if count==0||count>999||owned.saturating_add(count)>999||self.earned-self.spent<total{return Err("잔액이 부족하거나 보유 한도에 도달했습니다.".into())}self.spent+=total;*self.inventory.entry(id.into()).or_default()+=count;Ok(())}
 pub fn pendant(&mut self,c:&Catalog)->Result<(),String>{self.pendant_count(1,c)}
 pub fn pendant_count(&mut self,count:u32,c:&Catalog)->Result<(),String>{let initial=self.active.clone().ok_or("파트너와 펜던트가 필요합니다.")?;let owned=*self.inventory.get("rareCandy").unwrap_or(&0);if count==0||count>owned{return Err("사용할 펜던트 수량을 확인하세요.".into())}for _ in 0..count{*self.inventory.get_mut("rareCandy").unwrap()-=1;self.grow(100_000_000,c);if !self.active.as_ref().is_some_and(|p|p.started_at==initial.started_at&&p.continuing==initial.continuing&&p.path.starts_with(&initial.path)){break}}Ok(())}
 pub fn continue_training(&mut self,id:u32,c:&Catalog)->Result<(),String>{if self.active.is_none()||self.stored.is_some()||self.active.as_ref().is_some_and(|p|p.species_id==id||p.path.first()==Some(&id))||!self.is_special_collected(id)||!self.collected.contains(&id)||!c.missing(id,&self.collected,&[]){return Err("빈 보관 슬롯과 미수집 진화 경로가 필요합니다.".into())}self.stored=self.active.take();self.active=Some(Partner{species_id:id,path:vec![id],started_at:Some(Local::now().to_rfc3339()),continuing:true,..Default::default()});Ok(())}
 pub fn difficulty(&mut self,value:f64,c:&Catalog)->Result<(),String>{if !value.is_finite()||!(0.1..=2.).contains(&value){return Err("난이도 범위는 0.1~2.0입니다.".into())}let previous=self.settings.difficulty;let factor=value/previous;self.settings.difficulty=value;if let Some(p)=&mut self.active{p.progress=(p.progress as f64*factor).round()as u64}else{self.egg_progress=(self.egg_progress as f64*factor).round()as u64}if let Some(p)=&mut self.stored{p.progress=(p.progress as f64*factor).round()as u64}let _=c;Ok(())}
}
#[cfg(test)]
mod tests{
 use super::*;
 #[test]fn catalog_complete(){let c=Catalog::load();assert_eq!(c.species.len(),475);assert_eq!(c.species.values().filter(|s|s.stage==0).count(),7);for s in c.species.values(){for n in c.next(s.id){assert!(c.species.contains_key(&n))}}}
 #[test]fn ledger_never_replays(){let c=Catalog::load();let mut g=Game::default();g.observe("Codex","2026-10-29",100,&c);g.observe("Codex","2026-10-29",200,&c);g.observe("Codex","2026-10-29",10,&c);g.observe("Codex","2026-10-29",200,&c);assert_eq!(g.earned,100);g.observe("Codex","2026-10-30",50,&c);assert_eq!(g.earned,150);}
 #[test]fn hatch_overflow(){let c=Catalog::load();let mut g=Game::default();g.grow(5_000_050,&c);assert_eq!(g.active.unwrap().progress,50);}
 #[test]fn selection_and_growth(){let c=Catalog::load();let mut g=Game::demo();g.active.as_mut().unwrap().progress=0;let next=g.choices(&c)[0];g.select(next,&c).unwrap();g.grow(g.threshold(&c)+15,&c);assert_eq!(g.active.as_ref().unwrap().species_id,next);assert_eq!(g.progress(),15);}
 #[test]fn fusion_retains_partner_and_materials(){let c=Catalog::load();let r=c.rules.iter().find(|r|r.kind=="fusion").unwrap();let mut g=Game::demo();g.collected.extend(&r.ingredients);g.special(r.target,0,&c).unwrap();assert_eq!(g.active.as_ref().unwrap().species_id,2003);assert!(r.ingredients.iter().all(|n|g.collected.contains(n)));assert!(g.special(r.target,0,&c).is_err());}
 #[test]fn item_once(){let c=Catalog::load();let r=c.rules.iter().find(|r|r.kind=="item").unwrap();let mut g=Game::demo();g.collected.insert(r.source);let item=r.item.as_ref().unwrap();g.inventory.insert(item.clone(),2);g.special(r.target,0,&c).unwrap();assert_eq!(g.inventory[item],1);assert!(g.special(r.target,0,&c).is_err());assert_eq!(g.inventory[item],1);}
 #[test]fn difficulty_keeps_fraction(){let c=Catalog::load();let mut g=Game::demo();let before=g.progress()as f64/g.threshold(&c)as f64;g.difficulty(0.1,&c).unwrap();assert!((before-g.progress()as f64/g.threshold(&c)as f64).abs()<0.000001);}
 #[test]fn difficulty_preserves_stored_progress(){let c=Catalog::load();let mut g=Game::demo();g.stored=g.active.clone();g.difficulty(0.5,&c).unwrap();assert_eq!(g.stored.unwrap().progress,22_500_000);}
 #[test]fn insufficient_money_does_not_spend(){let mut g=Game::default();assert!(g.buy("rareCandy").is_err());assert_eq!(g.spent,0);}
 #[test]fn invalid_save_rejected(){let c=Catalog::load();let mut g=Game::demo();g.spent=g.earned+1;assert!(g.validate(&c).is_err());g.spent=0;g.active.as_mut().unwrap().path.push(2003);assert!(g.validate(&c).is_err());}
 #[test]fn continue_swap(){let c=Catalog::load();let mut g=Game::demo();let id=c.species.keys().copied().find(|id|*id!=2003&&*id!=2001&&c.missing(*id,&g.collected,&[])).unwrap();g.collected.insert(id);g.special_collected.insert(id);g.continue_training(id,&c).unwrap();assert_eq!(g.stored.as_ref().unwrap().progress,45_000_000);assert!(g.continue_training(id,&c).is_err());}
}
