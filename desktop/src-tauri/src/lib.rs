mod http;
mod model;
mod usage;
use std::{fs,io::Write,path::{Path,PathBuf},sync::{Arc,Mutex},time::Duration};
use tauri::{Manager,Emitter,State,WebviewWindowBuilder,WebviewUrl,WindowEvent};
use serde::{Serialize,Deserialize};
use model::{Catalog,Game,Settings,shop};
use usage::{Usage,Reader};
use base64::{Engine,engine::general_purpose::STANDARD};

struct Inner{game:Game,usage:Usage,reader:Reader,error:Option<String>}
struct Runtime{inner:Mutex<Inner>,catalog:Catalog,directory:PathBuf,demo:bool}
#[derive(Clone,Serialize)]
#[serde(rename_all="camelCase")]
struct Snapshot{game:Game,usage:Usage,threshold:u64,choices:Vec<u32>,ready:Vec<u32>,shop:Vec<model::Item>,demo:bool,save_path:String,error:Option<String>}
impl Runtime{
 fn snapshot(&self)->Result<Snapshot,String>{let i=self.inner.lock().map_err(|_|"상태 잠금 오류")?;let mut ready=Vec::new();for r in &self.catalog.rules{if !i.game.collected.contains(&r.target)&&i.game.eligible(r,i.usage.today()){ready.push(r.target)}}ready.sort();ready.dedup();Ok(Snapshot{threshold:i.game.threshold(&self.catalog),choices:i.game.choices(&self.catalog),shop:shop(),ready,game:i.game.clone(),usage:i.usage.clone(),demo:self.demo,save_path:self.directory.display().to_string(),error:i.error.clone()})}
 fn save(&self,game:&Game)->Result<(),String>{game.validate(&self.catalog)?;if self.demo{return Ok(())}save(&self.directory.join("state-v2.json"),game)}
 fn refresh(&self)->Result<(),String>{if self.demo{return Ok(())}let mut i=self.inner.lock().map_err(|_|"상태 잠금 오류")?;let settings=i.game.settings.clone();let usage=i.reader.scan(&settings);if usage.warnings.is_empty(){let mut next=i.game.clone();let today=chrono::Local::now().format("%Y-%m-%d").to_string();for p in &usage.providers{if p.files>0{next.observe(&p.provider,&today,p.today.total(),&self.catalog)}}match self.save(&next){Ok(())=>{i.game=next;i.error=None},Err(e)=>{i.error=Some(e);}}}i.usage=usage;Ok(())}
}
fn save(path:&Path,game:&Game)->Result<(),String>{let parent=path.parent().ok_or("저장 경로 오류")?;fs::create_dir_all(parent).map_err(|e|e.to_string())?;let bytes=serde_json::to_vec_pretty(game).map_err(|e|e.to_string())?;let mut file=tempfile::NamedTempFile::new_in(parent).map_err(|e|e.to_string())?;file.write_all(&bytes).and_then(|_|file.as_file().sync_all()).map_err(|e|e.to_string())?;if path.exists(){fs::copy(path,path.with_extension("json.bak")).map_err(|e|e.to_string())?;}file.persist(path).map_err(|e|e.to_string())?;Ok(())}
#[tauri::command]
async fn get_snapshot(state:State<'_,Arc<Runtime>>)->Result<Snapshot,String>{let rt=state.inner().clone();tauri::async_runtime::spawn_blocking(move||rt.snapshot()).await.map_err(|e|e.to_string())?}
fn broadcast(app:&tauri::AppHandle,rt:&Runtime){if let Ok(s)=rt.snapshot(){let _=app.emit("snapshot",s);}}
#[tauri::command]
async fn refresh(app:tauri::AppHandle,state:State<'_,Arc<Runtime>>)->Result<Snapshot,String>{let rt=state.inner().clone();tauri::async_runtime::spawn_blocking(move||{rt.refresh()?;broadcast(&app,&rt);rt.snapshot()}).await.map_err(|e|e.to_string())?}
#[derive(Deserialize)]
#[serde(rename_all="camelCase")]
struct Action{kind:String,id:Option<u32>,item:Option<String>,count:Option<u32>,settings:Option<Settings>}
fn apply(game:&mut Game,action:Action,today:u64,c:&Catalog)->Result<(),String>{
 let id=action.id.unwrap_or(0);
 match action.kind.as_str(){
 "select"=>game.select(id,c)?,
 "special"=>game.special(id,today,c)?,
 "buyEgg"=>game.buy_egg(c)?,
 "buy"=>game.buy_count(action.item.as_deref().ok_or("아이템이 없습니다.")?,action.count.unwrap_or(1))?,
 "pendant"=>game.pendant_count(action.count.unwrap_or(1),c)?,
 "continue"=>game.continue_training(id,c)?,
 "swap"=>{if game.active.is_none()||game.stored.is_none(){return Err("교환할 보관 파트너가 없습니다.".into())}std::mem::swap(&mut game.active,&mut game.stored)},
 "settings"=>{let settings=action.settings.ok_or("설정이 없습니다.")?;if !["ko","en"].contains(&settings.language.as_str())||![0,60,120,300,900].contains(&settings.refresh_interval)||!["powerSaver","balanced","smooth"].contains(&settings.animation_quality.as_str())||!["used","remaining"].contains(&settings.limit_display_mode.as_str())||settings.representative_id.is_some_and(|id|!game.collected.contains(&id)){return Err("설정 값을 확인하세요.".into())}for path in settings.codex_roots.iter().chain(&settings.claude_roots){if !Path::new(path).is_absolute()||!Path::new(path).is_dir(){return Err(format!("존재하는 절대 폴더 경로를 입력하세요: {path}"))}}game.difficulty(settings.difficulty,c)?;game.settings=settings;},
 "togglePet"=>game.settings.show_pet=!game.settings.show_pet,
 _=>return Err("알 수 없는 동작입니다.".into())
 }game.validate(c)
}
#[tauri::command]
async fn mutate(app:tauri::AppHandle,state:State<'_,Arc<Runtime>>,action:Action)->Result<Snapshot,String>{
 let rt=state.inner().clone();tauri::async_runtime::spawn_blocking(move||{
 {let mut i=rt.inner.lock().map_err(|_|"상태 잠금 오류")?;let mut next=i.game.clone();apply(&mut next,action,i.usage.today(),&rt.catalog)?;rt.save(&next)?;i.game=next;}
 sync_pet(&app,&rt)?;broadcast(&app,&rt);rt.snapshot()
 }).await.map_err(|e|e.to_string())?
}
fn show_main(app:&tauri::AppHandle){if let Some(w)=app.get_webview_window("main"){let _=w.show();let _=w.unminimize();let _=w.set_focus();}}
fn sync_pet(app:&tauri::AppHandle,rt:&Runtime)->Result<(),String>{
 let settings=rt.inner.lock().map_err(|_|"상태 잠금 오류")?.game.settings.clone();
 if settings.show_pet{let w=if let Some(w)=app.get_webview_window("pet"){w}else{WebviewWindowBuilder::new(app,"pet",WebviewUrl::App("index.html?surface=pet".into())).title("DigiMonTokenBar · 파트너").inner_size(230.,350.).decorations(false).resizable(false).skip_taskbar(true).visible(false).build().map_err(|e|e.to_string())?};w.set_always_on_top(settings.pet_topmost).map_err(|e|e.to_string())?;w.show().map_err(|e|e.to_string())?;}else if let Some(w)=app.get_webview_window("pet"){w.hide().map_err(|e|e.to_string())?;}Ok(())
}
#[tauri::command]
fn open_main(app:tauri::AppHandle){show_main(&app);}
#[tauri::command]
fn quit_app(app:tauri::AppHandle){app.exit(0);}
#[tauri::command]
fn open_profile_source(id:u32)->Result<(),String>{use std::os::windows::process::CommandExt;let data:serde_json::Value=serde_json::from_str(include_str!("../../../Sources/PokeTokenBar/Resources/Digimon/species-info.json")).map_err(|e|e.to_string())?;let source=data["records"].as_array().ok_or("프로필 데이터 오류")?.iter().find(|entry|entry["id"].as_u64()==Some(id as u64)).and_then(|entry|entry["source"].as_str()).ok_or("프로필 출처 없음")?;if !source.starts_with("https://digimon.net/"){return Err("공식 프로필 주소가 아닙니다.".into())}std::process::Command::new("rundll32.exe").args(["url.dll,FileProtocolHandler",source]).creation_flags(0x08000000).spawn().map_err(|e|e.to_string())?;Ok(())}
#[tauri::command]
async fn export_save(state:State<'_,Arc<Runtime>>)->Result<bool,String>{let rt=state.inner().clone();tauri::async_runtime::spawn_blocking(move||{let game=rt.inner.lock().map_err(|_|"상태 잠금 오류")?.game.clone();let Some(path)=rfd::FileDialog::new().set_file_name("DigiMonTokenBar.digimon2").add_filter("DigiMonTokenBar 저장",&["digimon2"]).save_file()else{return Ok(false)};save(&path,&game)?;Ok(true)}).await.map_err(|e|e.to_string())?}
#[tauri::command]
async fn import_save(app:tauri::AppHandle,state:State<'_,Arc<Runtime>>)->Result<Option<Snapshot>,String>{let rt=state.inner().clone();tauri::async_runtime::spawn_blocking(move||{
 let Some(path)=rfd::FileDialog::new().add_filter("DigiMonTokenBar 저장",&["digimon2"]).pick_file()else{return Ok(None)};
 if fs::metadata(&path).map_err(|e|e.to_string())?.len()>4_000_000{return Err("저장 파일이 너무 큽니다.".into())}
 let mut game:Game=serde_json::from_slice(&fs::read(path).map_err(|e|e.to_string())?).map_err(|e|format!("저장 형식 오류: {e}"))?;game.validate(&rt.catalog)?;
 if rfd::MessageDialog::new().set_title("저장 불러오기").set_description(format!("현재 진행 상황을 노트북 {}종의 저장으로 교체할까요? 현재 저장은 .bak로 보관됩니다.",game.collected.len())).set_buttons(rfd::MessageButtons::OkCancel).show()!=rfd::MessageDialogResult::Ok{return Ok(None)}
 game.initialized.clear();game.ledger.clear();
 {let mut i=rt.inner.lock().map_err(|_|"상태 잠금 오류")?;rt.save(&game)?;i.game=game;}
 sync_pet(&app,&rt)?;rt.refresh()?;broadcast(&app,&rt);Ok(Some(rt.snapshot()?))
 }).await.map_err(|e|e.to_string())?}

fn page_image_url(html:&str)->Option<String>{
 let tags=regex::Regex::new(r"(?is)<meta\b[^>]*>").ok()?;
 let attrs=regex::Regex::new(r#"(?is)\b(property|content)\s*=\s*["']([^"']*)["']"#).ok()?;
 for tag in tags.find_iter(html){let mut property=String::new();let mut content=String::new();for attr in attrs.captures_iter(tag.as_str()){match attr[1].to_ascii_lowercase().as_str(){"property"=>property=attr[2].to_ascii_lowercase(),"content"=>content=attr[2].replace("&amp;","&").replace("&#38;","&"),_=>()}}if property=="og:image"{if let Ok(url)=url::Url::parse(&content){if url.scheme()=="https"&&url.host_str().is_some_and(|h|h.ends_with(".wixmp.com")){return Some(content)}}}}None
}

#[tauri::command]
async fn get_artwork(state:State<'_,Arc<Runtime>>,id:Option<u32>,asset:Option<String>)->Result<String,String>{
 let rt=state.inner().clone();tauri::async_runtime::spawn_blocking(move||{
 let key=if let Some(id)=id{if !rt.catalog.species.contains_key(&id){return Err("알 수 없는 디지몬".into())}format!("species-{id}")}else{let key=asset.ok_or("이미지 키 없음")?;let items:serde_json::Value=serde_json::from_str(include_str!("../../src/shop.json")).map_err(|e|e.to_string())?;if !["gennai","digitama-adventure"].contains(&key.as_str())&&!items.as_array().ok_or("아이템 목록 오류")?.iter().any(|i|i["asset"].as_str()==Some(key.as_str())){return Err("알 수 없는 아이템 이미지".into())}key};
 let cache=rt.directory.join("artwork-v1");fs::create_dir_all(&cache).map_err(|e|e.to_string())?;let file=cache.join(format!("{key}.img"));let bytes=if file.exists(){fs::read(&file).map_err(|e|e.to_string())?}else{
 let sources:serde_json::Value=serde_json::from_str(include_str!("../../../Sources/PokeTokenBar/Resources/Digimon/external-artwork.json")).map_err(|e|e.to_string())?;let src=&sources[&key];let url=src["url"].as_str().ok_or("이미지 출처 없음")?;if !url.starts_with("https://"){return Err("이미지 주소 오류".into())}
 let resolved=if src["pageImage"].as_bool()==Some(true){let (page,_)=http::fetch(url,4_000_000)?;let html=String::from_utf8(page).map_err(|e|e.to_string())?;page_image_url(&html).ok_or("원본 이미지 주소를 읽지 못했습니다.")?}else{url.to_owned()};let (bytes,mime)=http::fetch(&resolved,8_000_000)?;if !mime.starts_with("image/")||mime.contains("svg"){return Err("지원하지 않는 이미지 형식".into())}let mut temp=tempfile::NamedTempFile::new_in(&cache).map_err(|e|e.to_string())?;temp.write_all(&bytes).map_err(|e|e.to_string())?;temp.persist(&file).map_err(|e|e.to_string())?;bytes};
 let mime=if bytes.starts_with(b"\x89PNG"){"image/png"}else if bytes.starts_with(b"\xff\xd8"){"image/jpeg"}else if bytes.starts_with(b"RIFF"){"image/webp"}else if bytes.starts_with(b"GIF8"){"image/gif"}else{return Err("이미지 파일 형식 오류".into())};Ok(format!("data:{mime};base64,{}",STANDARD.encode(bytes)))
 }).await.map_err(|e|e.to_string())?
}
fn tray(app:&tauri::AppHandle)->tauri::Result<()>{
 use tauri::{menu::{Menu,MenuItem},tray::{TrayIconBuilder,TrayIconEvent,MouseButton,MouseButtonState}};
 let open=MenuItem::with_id(app,"open","대시보드 열기",true,None::<&str>)?;let pet=MenuItem::with_id(app,"pet","바탕화면 파트너 표시 / 숨기기",true,None::<&str>)?;let quit=MenuItem::with_id(app,"quit","종료",true,None::<&str>)?;
 let menu=Menu::with_items(app,&[&open,&pet,&quit])?;
 TrayIconBuilder::with_id("main-tray").icon(tauri::image::Image::from_bytes(include_bytes!("../icons/icon.png"))?).tooltip("DigiMonTokenBar").menu(&menu).show_menu_on_left_click(false)
 .on_menu_event(|app,event|match event.id.as_ref(){"open"=>show_main(app),"quit"=>app.exit(0),"pet"=>{let rt=app.state::<Arc<Runtime>>().inner().clone();{if let Ok(mut i)=rt.inner.lock(){let mut next=i.game.clone();next.settings.show_pet=!next.settings.show_pet;if rt.save(&next).is_ok(){i.game=next;}}}let _=sync_pet(app,&rt);broadcast(app,&rt);},_=>()})
 .on_tray_icon_event(|tray,event|{if let TrayIconEvent::Click{button:MouseButton::Left,button_state:MouseButtonState::Up,position,..}=event{let app=tray.app_handle();if let Some(w)=app.get_webview_window("popup"){if w.is_visible().unwrap_or(false){let _=w.hide();}else{let mut x=position.x-440.;let mut y=position.y-780.;if let Ok(Some(m))=w.current_monitor(){let pos=m.position();let size=m.size();let scale=m.scale_factor();let width=440.*scale;let height=760.*scale;x=(position.x-width).clamp(pos.x as f64,(pos.x as f64+size.width as f64-width).max(pos.x as f64));y=(position.y-height-12.).clamp(pos.y as f64,(pos.y as f64+size.height as f64-height).max(pos.y as f64));}let _=w.set_position(tauri::PhysicalPosition::new(x as i32,y as i32));let _=w.show();let _=w.set_focus();}}}}).build(app)?;Ok(())
}
pub fn run(){
 tauri::Builder::default().plugin(tauri_plugin_single_instance::init(|app,_,_|show_main(app)))
 .setup(|app|{
  let demo=std::env::args().any(|a|a=="--demo");let directory=std::env::var_os("DIGIMON_DATA_DIR").map(PathBuf::from).unwrap_or(app.path().app_local_data_dir()?);fs::create_dir_all(&directory)?;
  let catalog=Catalog::load();let path=directory.join("state-v2.json");let game=if demo{Game::demo_collection()}else if path.exists(){match fs::read(&path).map_err(|e|e.to_string()).and_then(|v|serde_json::from_slice::<Game>(&v).map_err(|e|e.to_string())).and_then(|g|{g.validate(&catalog)?;Ok(g)}){Ok(g)=>g,Err(e)=>{rfd::MessageDialog::new().set_title("저장 파일을 열지 못했습니다").set_description(format!("{e}\n기존 저장은 변경하지 않았습니다.\n{}",directory.display())).show();return Err(e.into())}}}else{Game::default()};
  let usage=if demo{Usage::demo()}else{Usage::default()};let rt=Arc::new(Runtime{inner:Mutex::new(Inner{game,usage,reader:Reader::default(),error:None}),catalog,directory,demo});app.manage(rt.clone());
  WebviewWindowBuilder::new(app,"popup",WebviewUrl::App("index.html?surface=popup".into())).title("DigiMonTokenBar · 트레이").inner_size(440.,760.).resizable(false).skip_taskbar(true).visible(false).build()?;
  tray(app.handle())?;sync_pet(app.handle(),&rt).map_err(std::io::Error::other)?;
  let handle=app.handle().clone();std::thread::spawn(move||{let mut elapsed=0u64;let _=rt.refresh();broadcast(&handle,&rt);loop{std::thread::sleep(Duration::from_secs(1));elapsed=elapsed.saturating_add(1);let interval=rt.inner.lock().map(|i|i.game.settings.refresh_interval).unwrap_or(60);if interval>0&&elapsed>=interval{elapsed=0;if let Err(e)=rt.refresh(){if let Ok(mut i)=rt.inner.lock(){i.error=Some(e)}}broadcast(&handle,&rt);}}});Ok(())
 })
 .on_window_event(|window,event|match event{WindowEvent::CloseRequested{api,..}=>{api.prevent_close();let _=window.hide();},WindowEvent::Focused(false)if window.label()=="popup"=>{let _=window.hide();},_=>()})
 .invoke_handler(tauri::generate_handler![get_snapshot,refresh,mutate,get_artwork,export_save,import_save,open_main,quit_app,open_profile_source])
 .run(tauri::generate_context!()).expect("Tauri application error");
}
#[cfg(test)]mod tests{
 use super::*;
 #[test]fn page_image_accepts_only_original_https_host(){assert_eq!(page_image_url(r#"<meta content='https://images-wixmp-test.wixmp.com/image.png?a=1&amp;b=2' property='og:image'>"#),Some("https://images-wixmp-test.wixmp.com/image.png?a=1&b=2".into()));assert!(page_image_url(r#"<meta property='og:image' content='http://images.wixmp.com/image.png'>"#).is_none());assert!(page_image_url(r#"<meta property='og:image' content='https://evilwixmp.com/image.png'>"#).is_none());}
 #[test]fn save_backup_and_validation(){let dir=tempfile::tempdir().unwrap();let path=dir.path().join("state.json");let mut g=Game::demo();save(&path,&g).unwrap();g.earned+=100;save(&path,&g).unwrap();let old:Game=serde_json::from_slice(&fs::read(path.with_extension("json.bak")).unwrap()).unwrap();assert_eq!(old.earned,760_000_000);let current:Game=serde_json::from_slice(&fs::read(path).unwrap()).unwrap();assert_eq!(current.earned,760_000_100);}
}

#[cfg(test)]
mod qa_tests;
