use std::{collections::{BTreeMap,BTreeSet},fs::{self,File},io::{BufRead,BufReader},path::{Path,PathBuf},time::SystemTime};
use serde::Serialize;
use serde_json::Value;
use chrono::{DateTime,Local,Datelike};
use crate::model::Settings;

#[derive(Clone,Serialize,Debug,Default)]
#[serde(rename_all="camelCase")]
pub struct Bucket{pub input:u64,pub output:u64,pub cache_read:u64,pub cache_write:u64}
impl Bucket{pub fn total(&self)->u64{self.input+self.output+self.cache_read+self.cache_write}fn add(&mut self,o:&Self){self.input+=o.input;self.output+=o.output;self.cache_read+=o.cache_read;self.cache_write+=o.cache_write}}
#[derive(Clone,Debug)]
pub struct Entry{pub id:String,pub time:i64,pub day:String,pub usage:Bucket}
#[derive(Clone,Debug,PartialEq,Eq)]
struct Vector{input:u64,cached:u64,output:u64,total:u64}
impl Vector{fn read(v:&Value)->Self{Self{input:num(v,"input_tokens"),cached:num(v,"cached_input_tokens"),output:num(v,"output_tokens"),total:num(v,"total_tokens")}}}
#[derive(Clone,Debug)]
struct Event{entry:Entry,cumulative:Option<Vector>,last:Vector}
#[derive(Clone,Debug,Default)]
pub struct Rollout{id:String,parent:Option<String>,subagent:bool,forked_at:i64,events:Vec<Event>}
#[derive(Clone,Serialize,Debug,Default)]
#[serde(rename_all="camelCase")]
pub struct ProviderUsage{pub provider:String,pub files:u64,pub today:Bucket,pub week:u64,pub month:u64,pub days:BTreeMap<String,u64>}
#[derive(Clone,Serialize,Debug,Default)]
#[serde(rename_all="camelCase")]
pub struct Usage{pub providers:Vec<ProviderUsage>,pub warnings:Vec<String>,pub updated_at:String,pub roots:BTreeMap<String,Vec<String>>}
impl Usage{
 pub fn today(&self)->u64{self.providers.iter().map(|p|p.today.total()).sum()}
 pub fn demo()->Self{let date=Local::now().date_naive();let week_start=(date-chrono::Duration::days(date.weekday().num_days_from_monday()as i64)).format("%Y-%m-%d").to_string();let provider=|name:&str,today:Bucket|{let total=today.total();let mut days=BTreeMap::new();for day in 1..=date.day(){let key=date.with_day(day).unwrap().format("%Y-%m-%d").to_string();let amount=if day==date.day(){total}else{(total as f64*(0.3+((day*7)%9)as f64/12.))as u64};days.insert(key,amount);}ProviderUsage{provider:name.into(),files:12,week:days.iter().filter(|(key,_)|key.as_str()>=week_start.as_str()).map(|(_,n)|*n).sum(),month:days.values().sum(),days,today}};Self{providers:vec![provider("Codex",Bucket{input:10_400_000,output:5_200_000,cache_read:3_900_000,cache_write:1_300_000}),provider("Claude Code",Bucket{input:4_200_000,output:2_100_000,cache_read:1_500_000,cache_write:600_000})],updated_at:Local::now().to_rfc3339(),..Default::default()}}
}
fn num(v:&Value,key:&str)->u64{v.get(key).and_then(|n|n.as_f64().or_else(||n.as_str().and_then(|s|s.parse().ok()))).filter(|n|n.is_finite()&&*n>=0.).map(|n|n.min(1_000_000_000_000.)as u64).unwrap_or(0)}
fn text<'a>(v:&'a Value,key:&str)->Option<&'a str>{v.get(key).and_then(Value::as_str)}
fn timestamp(v:&Value)->Option<(i64,String)>{DateTime::parse_from_rfc3339(text(v,"timestamp")?).ok().map(|t|(t.timestamp_millis(),t.with_timezone(&Local).format("%Y-%m-%d").to_string()))}
pub fn parse_claude(path:&Path)->Result<Vec<Entry>,String>{
 let reader=BufReader::new(File::open(path).map_err(|e|e.to_string())?);let mut entries=Vec::new();
 for (index,line) in reader.lines().enumerate(){let line=line.map_err(|e|e.to_string())?;if !line.contains("\"usage\""){continue}let Ok(v)=serde_json::from_str::<Value>(&line)else{continue};if text(&v,"type")!=Some("assistant"){continue}let Some((time,day))=timestamp(&v)else{continue};let m=&v["message"];let u=&m["usage"];if !u.is_object(){continue}let id=text(m,"id").map(str::to_owned).unwrap_or_else(||format!("{}:{index}",path.file_stem().unwrap_or_default().to_string_lossy()));let request=text(&v,"requestId").unwrap_or("");entries.push(Entry{id:format!("claude:{id}:{request}"),time,day,usage:Bucket{input:num(u,"input_tokens"),output:num(u,"output_tokens"),cache_read:num(u,"cache_read_input_tokens"),cache_write:num(u,"cache_creation_input_tokens")}})}
 Ok(entries)
}
pub fn parse_codex(path:&Path)->Result<Rollout,String>{
 let reader=BufReader::new(File::open(path).map_err(|e|e.to_string())?);let mut result=Rollout{id:path.file_stem().unwrap_or_default().to_string_lossy().into(),..Default::default()};let mut meta_seen=false;let mut seen=BTreeSet::new();let mut previous:Option<Vector>=None;
 for line in reader.lines(){let line=line.map_err(|e|e.to_string())?;if !line.contains("token_count")&&!line.contains("session_meta"){continue}let Ok(v)=serde_json::from_str::<Value>(&line)else{continue};let p=&v["payload"];
 if text(&v,"type")==Some("session_meta"){if !meta_seen{result.id=text(p,"id").or_else(||text(p,"session_id")).unwrap_or(&result.id).to_owned();result.parent=text(p,"forked_from_id").or_else(||text(p,"parent_thread_id")).map(str::to_owned);result.subagent=text(p,"thread_source")==Some("subagent")||p["source"].get("subagent").is_some();result.forked_at=timestamp(&v).map(|t|t.0).unwrap_or(0);meta_seen=true}continue}
 if text(&v,"type")!=Some("event_msg")||text(p,"type")!=Some("token_count"){continue}let Some((time,day))=timestamp(&v)else{continue};let info=&p["info"];if !info["last_token_usage"].is_object(){continue}let last=Vector::read(&info["last_token_usage"]);let cumulative=info["total_token_usage"].is_object().then(||Vector::read(&info["total_token_usage"]));
 let signature=if let Some(c)=&cumulative{format!("{c:?}:{last:?}")}else{format!("{time}:{last:?}")};if !seen.insert(signature.clone()){continue}
 let cached=last.cached.min(last.input);let mut input=last.input-cached;
 if input+cached+last.output==0&&last.total>0&&cumulative.as_ref().map(|c|c.input+c.output==0||c.total==last.total||previous.as_ref().is_some_and(|p|c.total>p.total)).unwrap_or(true){input=last.total}
 let entry=Entry{id:format!("{}:{signature}",result.id),time,day,usage:Bucket{input,output:last.output,cache_read:cached,cache_write:0}};
 previous=cumulative.clone();result.events.push(Event{entry,cumulative,last});
 }Ok(result)
}
pub fn resolve(rollouts:&[Rollout])->Vec<Entry>{
 let mut by_id:BTreeMap<&str,&Rollout>=BTreeMap::new();for r in rollouts{if by_id.get(r.id.as_str()).map(|p|p.events.len()<r.events.len()).unwrap_or(true){by_id.insert(&r.id,r);}}
 let mut entries:BTreeMap<String,Entry>=BTreeMap::new();
 for r in by_id.values(){let mut skip=0;if let Some(parent_id)=&r.parent{
  if let Some(parent)=by_id.get(parent_id.as_str()){while skip<r.events.len()&&skip<parent.events.len()&&r.events[skip].cumulative.is_some()&&r.events[skip].cumulative==parent.events[skip].cumulative&&r.events[skip].last==parent.events[skip].last{skip+=1}}
  if skip==0&&!r.subagent{let mut previous=r.forked_at;for e in &r.events{if e.entry.time-previous>=1000{break}skip+=1;previous=e.entry.time}}
 }
 for e in r.events.iter().skip(skip){if e.entry.usage.total()>0{let en=&e.entry;if entries.get(&en.id).map(|o|o.time>en.time).unwrap_or(true){entries.insert(en.id.clone(),en.clone());}}}}
 entries.into_values().collect()
}
#[derive(Clone)]enum Data{Codex(Rollout),Claude(Vec<Entry>)}
struct Cached{size:u64,modified:SystemTime,data:Data}
#[derive(Default)]pub struct Reader{cache:BTreeMap<PathBuf,Cached>}
pub fn roots(s:&Settings)->BTreeMap<String,Vec<String>>{
 let home=std::env::var("USERPROFILE").or_else(|_|std::env::var("HOME")).unwrap_or_default();let ch=std::env::var("CODEX_HOME").unwrap_or_else(|_|format!("{home}/.codex"));
 let mut codex=vec![format!("{ch}/sessions"),format!("{ch}/archived_sessions")];codex.extend(s.codex_roots.clone());
 let mut claude=vec![format!("{home}/.claude/projects"),format!("{home}/.config/claude/projects")];if let Ok(paths)=std::env::var("CLAUDE_CONFIG_DIR"){for path in paths.split(',').map(str::trim).filter(|s|!s.is_empty()){claude.push(format!("{path}/projects"))}}claude.extend(s.claude_roots.clone());
 [("Codex".into(),codex),("Claude Code".into(),claude)].into_iter().collect()
}
impl Reader{
 pub fn scan(&mut self,s:&Settings)->Usage{self.scan_paths(roots(s))}
 pub(crate) fn scan_paths(&mut self,paths:BTreeMap<String,Vec<String>>)->Usage{
  let mut result=Usage{roots:paths.clone(),updated_at:Local::now().to_rfc3339(),..Default::default()};let today=Local::now().format("%Y-%m-%d").to_string();let date=Local::now().date_naive();let cutoff=(date-chrono::Duration::days(date.weekday().num_days_from_monday()as i64)).format("%Y-%m-%d").to_string();let month_start=date.with_day(1).unwrap().format("%Y-%m-%d").to_string();let mut all_seen=BTreeSet::new();
  for (provider,roots)in paths{let mut seen=BTreeSet::new();let mut codex=Vec::new();let mut claude:BTreeMap<String,Entry>=BTreeMap::new();let mut count=0;
  for root in roots{if !Path::new(&root).exists(){continue}for entry in walkdir::WalkDir::new(root).follow_links(false){let entry=match entry{Ok(v)=>v,Err(_)=>{result.warnings.push(format!("{provider} 폴더 일부에 접근할 수 없습니다."));continue}};if !entry.file_type().is_file()||entry.path().extension().and_then(|x|x.to_str())!=Some("jsonl"){continue}let path=entry.path().canonicalize().unwrap_or(entry.path().to_owned());if !seen.insert(path.clone()){continue}all_seen.insert(path.clone());count+=1;
  let parsed=(||->Result<Data,String>{let metadata=fs::metadata(&path).map_err(|e|e.to_string())?;let modified=metadata.modified().map_err(|e|e.to_string())?;if let Some(c)=self.cache.get(&path){if c.size==metadata.len()&&c.modified==modified{return Ok(c.data.clone())}}let data=if provider=="Codex"{Data::Codex(parse_codex(&path)?)}else{Data::Claude(parse_claude(&path)?)};self.cache.insert(path.clone(),Cached{size:metadata.len(),modified,data:data.clone()});Ok(data)})();
  let data=match parsed{Ok(v)=>Some(v),Err(_)=>{result.warnings.push(format!("{provider} 로그 일부를 읽지 못했습니다."));self.cache.get(&path).map(|c|c.data.clone())}};match data{Some(Data::Codex(r))=>codex.push(r),Some(Data::Claude(entries))=>{for e in entries{if claude.get(&e.id).map(|old|e.usage.total()>old.usage.total()).unwrap_or(true){claude.insert(e.id.clone(),e);}}},None=>()}
  }}
  let entries=if provider=="Codex"{resolve(&codex)}else{claude.into_values().collect()};let mut p=ProviderUsage{provider,files:count,..Default::default()};for e in entries{if e.day==today{p.today.add(&e.usage)}if e.day>=cutoff&&e.day<=today{p.week+=e.usage.total()}if e.day>=month_start&&e.day<=today{p.month+=e.usage.total();*p.days.entry(e.day).or_default()+=e.usage.total()}}result.providers.push(p);
  }self.cache.retain(|p,_|all_seen.contains(p));result.warnings.sort();result.warnings.dedup();result
 }
}
#[cfg(test)]mod tests{
 use super::*;
 fn fixture(group:&str,name:&str)->PathBuf{Path::new(env!("CARGO_MANIFEST_DIR")).join(format!("../../Tests/PokeTokenBarTests/Fixtures/{group}/{name}.jsonl"))}
 #[test]fn fork_parity(){let rs:Vec<_>=["parent","child","sibling"].iter().map(|n|parse_codex(&fixture("CodexFork",n)).unwrap()).collect();assert_eq!(resolve(&rs).iter().map(|e|e.usage.total()).sum::<u64>(),369_215);}
 #[test]fn subagent_parity(){for (p,c,total)in [("parent","child",115_607),("parent-v145","child-v145",106_583)]{let rs:Vec<_>=[p,c].iter().map(|n|parse_codex(&fixture("CodexSubagent",n)).unwrap()).collect();assert_eq!(resolve(&rs).iter().map(|e|e.usage.total()).sum::<u64>(),total)}}
 #[test]fn duplicate_files(){let p=parse_codex(&fixture("CodexFork","parent")).unwrap();assert_eq!(resolve(&[p.clone(),p]).iter().map(|e|e.usage.total()).sum::<u64>(),312_814);}
 #[test]fn orphan_subagent(){let r=parse_codex(&fixture("CodexSubagent","child-v145")).unwrap();assert!(r.subagent);assert_eq!(resolve(&[r.clone()]).len(),r.events.iter().filter(|e|e.entry.usage.total()>0).count());}
 #[test]fn claude_cache_and_broken_tail(){use std::io::Write;let mut f=tempfile::NamedTempFile::new().unwrap();write!(f,"{}\n{{",r#"{"type":"assistant","timestamp":"2026-10-29T01:00:00Z","message":{"id":"m1","usage":{"input_tokens":10,"output_tokens":20,"cache_read_input_tokens":30,"cache_creation_input_tokens":40}}}"#).unwrap();let es=parse_claude(f.path()).unwrap();assert_eq!(es.len(),1);assert_eq!(es[0].usage.total(),100);}
}
