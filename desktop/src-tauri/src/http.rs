use std::{ffi::c_void,ptr::{null,null_mut}};
use windows_sys::Win32::Networking::WinHttp::*;
struct Handle(*mut c_void);
impl Handle{fn new(p:*mut c_void)->Result<Self,String>{if p.is_null(){Err(std::io::Error::last_os_error().to_string())}else{Ok(Self(p))}}}
impl Drop for Handle{fn drop(&mut self){unsafe{WinHttpCloseHandle(self.0);}}}
fn wide(s:&str)->Vec<u16>{s.encode_utf16().chain(Some(0)).collect()}
fn checked(ok:i32)->Result<(),String>{if ok==0{Err(std::io::Error::last_os_error().to_string())}else{Ok(())}}
fn header(request:&Handle,kind:u32)->Result<String,String>{unsafe{let mut count=0u32;WinHttpQueryHeaders(request.0,kind,null(),null_mut(),&mut count,null_mut());if count==0||count>65536{return Err("HTTP 헤더를 읽지 못했습니다.".into())}let mut buf=vec![0u16;count as usize/2+1];checked(WinHttpQueryHeaders(request.0,kind,null(),buf.as_mut_ptr().cast(),&mut count,null_mut()))?;Ok(String::from_utf16_lossy(&buf[..count as usize/2]).trim_end_matches('\0').to_owned())}}
/// HTTPS through Windows' certificate store; system proxy settings, bounded body and timeouts.
pub fn fetch(address:&str,limit:usize)->Result<(Vec<u8>,String),String>{
 let url=url::Url::parse(address).map_err(|e|e.to_string())?;
 if url.scheme()!="https"||!url.username().is_empty()||url.password().is_some(){return Err("HTTPS 이미지 주소가 필요합니다.".into())}
 let host=wide(url.host_str().ok_or("이미지 호스트 없음")?);let mut object=url.path().to_owned();if let Some(q)=url.query(){object.push('?');object.push_str(q)}let path=wide(&object);let agent=wide("DigiMonTokenBar/0.2");let verb=wide("GET");
 unsafe{
  let session=Handle::new(WinHttpOpen(agent.as_ptr(),WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY,null(),null(),0))?;
  checked(WinHttpSetTimeouts(session.0,12000,12000,12000,12000))?;
  let connection=Handle::new(WinHttpConnect(session.0,host.as_ptr(),url.port_or_known_default().unwrap_or(443),0))?;
  let request=Handle::new(WinHttpOpenRequest(connection.0,verb.as_ptr(),path.as_ptr(),null(),null(),null(),WINHTTP_FLAG_SECURE))?;
  // Keep HTTPS redirects but reject downgrades to HTTP.
  let policy=WINHTTP_OPTION_REDIRECT_POLICY_DISALLOW_HTTPS_TO_HTTP;
  checked(WinHttpSetOption(request.0,WINHTTP_OPTION_REDIRECT_POLICY,(&policy as *const u32).cast(),4))?;
  checked(WinHttpSendRequest(request.0,null(),0,null(),0,0,0))?;checked(WinHttpReceiveResponse(request.0,null_mut()))?;
  let status=header(&request,WINHTTP_QUERY_STATUS_CODE)?;if status!="200"{return Err(format!("이미지 HTTP 오류: {status}"))}
  let mime=header(&request,WINHTTP_QUERY_CONTENT_TYPE)?;let mut bytes=Vec::new();let mut block=[0u8;16384];
  loop{let mut count=0;checked(WinHttpReadData(request.0,block.as_mut_ptr().cast(),block.len()as u32,&mut count))?;if count==0{break}if bytes.len()+count as usize>limit{return Err("이미지 다운로드 크기 초과".into())}bytes.extend_from_slice(&block[..count as usize]);}
  Ok((bytes,mime))
 }
}
#[cfg(test)]mod tests{use super::*;#[test]fn rejects_non_https(){assert!(fetch("http://example.com/x",10).is_err());assert!(fetch("file:///C:/x",10).is_err());}#[test]fn rejects_credentials(){assert!(fetch("https://user:password@example.com/x",10).is_err());}}
