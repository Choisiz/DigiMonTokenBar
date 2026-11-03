'use strict';
const copy = {
 en: {
  skip:'Skip to content', navExplore:'Explore', eyebrow:'A DIGITAL COMPANION FOR YOUR DESKTOP', heroLine1:'You code.', heroLine2:'They evolve.',
  heroDescription:'Give your everyday tokens a second life. Raise a Digimon alongside your Claude Code and Codex sessions, on macOS or Windows.', getApp:'Get DigiMonTokenBar', watchFusion:'Watch a fusion', terminal:'LOCAL TOKENS → DIGITAL LIFE', sampleLabel:'Actual app UI · sample data',
  factSpecies:'Digimon to discover', factRoots:'baby Digimon to begin with', factLocalValue:'local', factLocal:'usage processing on your device',
  experienceEyebrow:'01 / YOUR EVERYDAY COMPANION',experienceTitle:'A little progress.\nA new possibility.',experienceIntro:'Keep your usual workflow. The tokens you already use become a reason to check in on your partner.',
  growTitle:'Your work, their next chapter.',growBody:'Local token usage fills the growth gauge. Pick your next branch, or let automatic evolution prioritize an ordinary form you haven’t collected.',collectTitle:'One Notebook. So many stories.',collectBody:'Browse 475 Digimon, filter by stage and explore profile excerpts, signature moves and branching evolution paths.',tagProfile:'PROFILES',tagMoves:'MOVES',tagBranches:'BRANCHES',unlockTitle:'Some evolutions take a little more.',unlockBody:'Collect fusion partners, use designated items or reach a daily-token goal. The orange lightbulb tells you when a special evolution is ready.',ready:'SPECIAL EVOLUTION READY',
  notebookTitle:'Every discovery\ngets a place.',notebookBody:'Your collection stays with you, even as the next partner begins a new journey.',moreScreens:'Explore all the screens',
  fusionEyebrow:'02 / DATA CONNECTED',fusionTitle:'Two partners.\nOne new beginning.',fusionBody:'WarGreymon + MetalGarurumon → Omnimon. Watch their data connect, reconstruct and reveal a new form.',fusionNote:'Rendered from the app’s fusion sequence. No personal usage data. Character artwork belongs to its respective rights holders.',videoFallback:'Your browser cannot play this video.',
  installEyebrow:'03 / START YOUR CONNECTION',installTitle:'A new partner\nis one install away.',installIntro:'An unofficial, non-commercial fan project. Open source, with no account or real-money purchases in the app.',macRequirement:'Apple Silicon · macOS 14 or later',downloadMac:'Download for Mac',brewLabel:'Or install with Homebrew',copy:'Copy',copied:'Copied!',copySuccess:'Installation command copied.',copyFailed:'Select and copy the command above.',signingNote:'Ad-hoc signed, not Apple-notarized. Homebrew removes the app’s quarantine attribute; direct downloads may need approval in Privacy & Security.',installGuide:'Read the installation guide ↗',
  windowsRequirement:'Windows x64 · WebView2 Runtime required',windowsTitle:'Windows 1.0.0 is here.',windowsBody:'The Windows preview is here, with a dashboard, system tray and floating partner. Verified on Windows 11 x64.',downloadWindows:'Download for Windows',windowsStep1:'Download and extract the ZIP.',windowsStep2:'Run DigiMonTokenBar.exe. No developer tools needed.',windowsStep3:'Use Claude Code or Codex. Add log folders in Settings if needed.',windowsNote:'Closing the window keeps it in the tray. Quit completely before updating. Account quotas, pet size and bubble alerts are not yet supported; English is partial. Saves are separate from macOS.',windowsLink:'Windows setup and usage ↗',privacy:'Usage logs are processed locally. The app fetches artwork and may contact configured usage services; see the privacy details in the README.',releases:'Releases ↗',credits:'Credits & rights ↗',creditBody:'Unofficial Digimon fan project. Based on PokeTokenBar by chattymin and contributors, with its MIT notices retained. Digimon © Akiyoshi Hongo / Toei Animation / BANDAI and respective rights holders. Code is MIT; third-party artwork, text, data and trademarks have separate rights. Attribution does not grant permission or imply endorsement.',original:'Original project ↗',screensNote:'Screens shown with synthetic sample data. No analytics or tracking cookies on this page.',
  homeAlt:'English DigiMonTokenBar home with Agumon, evolution progress and token usage',notebookAlt:'Notebook collection with growth-stage filters and collected species counter',detailAlt:'WarGreymon detail with English profile, moves and evolution requirements',videoLabel:'Omnimon fusion animation'
 },
 ko: {
  skip:'본문으로 건너뛰기',navExplore:'기능 살펴보기',eyebrow:'데스크톱 속, 작은 디지털 생명',heroLine1:'당신은 코딩을.',heroLine2:'디지몬은 진화를.',heroDescription:'매일 쓰는 토큰에 또 하나의 의미를. Claude Code와 Codex로 작업하는 동안, macOS와 Windows에서 디지몬도 함께 자랍니다.',getApp:'DigiMonTokenBar 시작하기',watchFusion:'융합 연출 보기',terminal:'매일의 토큰 → 디지털 생명',sampleLabel:'실제 앱 화면 · 가상 샘플 데이터',
  factSpecies:'발견할 수 있는 디지몬',factRoots:'여정의 시작, 유년기 디지몬',factLocalValue:'로컬',factLocal:'내 기기에서 사용량 처리',experienceEyebrow:'01 / 일상 속 작은 파트너',experienceTitle:'작은 진전이,\n새로운 가능성으로.',experienceIntro:'평소처럼 코딩하세요. 이미 사용하고 있는 토큰이 파트너의 다음 모습을 기다리는 이유가 됩니다.',growTitle:'당신의 작업이, 다음 성장으로.',growBody:'로컬 토큰 사용량으로 성장 게이지를 채웁니다. 다음 진화를 직접 고르거나, 아직 수집하지 않은 일반 진화체를 우선하는 자동 진화에 맡기세요.',collectTitle:'하나의 노트북, 수많은 이야기.',collectBody:'475종의 디지몬을 모으고 성장 단계로 찾아보세요. 도감 설명과 필살기, 다음 진화 경로까지 함께 확인할 수 있습니다.',tagProfile:'도감 정보',tagMoves:'필살기',tagBranches:'분기 진화',unlockTitle:'특별한 진화에는, 특별한 조건을.',unlockBody:'융합 파트너를 모으고, 전용 아이템을 사용하거나 당일 토큰 목표를 달성하세요. 특수 진화가 준비되면 주황색 전구가 알려줍니다.',ready:'특수 진화 준비 완료',notebookTitle:'모든 발견을\n기록하는 곳.',notebookBody:'다음 파트너가 새로운 여정을 시작해도, 지금까지의 수집 기록은 노트북에 남습니다.',moreScreens:'전체 화면 살펴보기',
  fusionEyebrow:'02 / 연결되는 데이터',fusionTitle:'두 파트너가 만나,\n새로운 시작으로.',fusionBody:'워그레이몬 + 메탈가루몬 → 오메가몬. 두 개체의 데이터가 연결되고, 재구성되어 새로운 모습을 드러냅니다.',fusionNote:'앱의 실제 융합 연출 코드로 렌더링한 영상입니다. 개인 사용 기록은 포함하지 않았으며, 캐릭터 이미지의 권리는 각 권리자에게 있습니다.',videoFallback:'이 브라우저에서는 영상을 재생할 수 없습니다.',
  installEyebrow:'03 / 새로운 연결의 시작',installTitle:'설치 한 번으로,\n새로운 파트너를.',installIntro:'비공식·비영리 팬 프로젝트입니다. 소스가 공개되어 있으며, 앱 계정이나 실제 결제 없이 사용할 수 있습니다.',macRequirement:'Apple Silicon · macOS 14 이상',downloadMac:'Mac용 다운로드',brewLabel:'또는 Homebrew로 설치',copy:'복사',copied:'복사 완료',copySuccess:'설치 명령을 복사했습니다.',copyFailed:'위 명령을 직접 선택해 복사해 주세요.',signingNote:'Ad-hoc 서명 앱으로, Apple 공증은 받지 않았습니다. Homebrew는 앱의 격리 속성을 제거하며, 직접 다운로드 시 개인정보 보호 및 보안에서 실행 허용이 필요할 수 있습니다.',installGuide:'자세한 설치 방법 보기 ↗',windowsRequirement:'Windows x64 · WebView2 Runtime 필요',windowsTitle:'Windows 1.0.0, 새로운 시작.',windowsBody:'대시보드·트레이·바탕화면 파트너를 제공하는 Windows 프리뷰를 추가했습니다. Windows 11 x64에서 검증했습니다.',downloadWindows:'Windows용 다운로드',windowsStep1:'ZIP을 다운로드하고 압축을 해제하세요.',windowsStep2:'DigiMonTokenBar.exe를 실행하세요. 개발 도구는 필요 없습니다.',windowsStep3:'Claude Code·Codex를 사용하세요. 필요하면 설정에서 로그 폴더를 추가하세요.',windowsNote:'창을 닫아도 트레이에서 계속 실행됩니다. 업데이트 전 완전히 종료하세요. 잔여 한도·펫 크기·말풍선 알림은 미지원이며 영어 번역은 일부 미완성입니다. macOS와 저장은 별도입니다.',windowsLink:'Windows 설치·사용법 보기 ↗',privacy:'사용 기록은 로컬에서 처리합니다. 앱은 이미지와 설정된 사용량 서비스에 접속할 수 있습니다. 자세한 내용은 README의 개인정보 안내를 확인하세요.',releases:'릴리스 ↗',credits:'출처·권리 안내 ↗',creditBody:'비공식 디지몬 팬 프로젝트입니다. chattymin과 기여자들의 PokeTokenBar를 기반으로 하며 원본 MIT 고지를 유지합니다. 디지몬 © 혼고 아키요시 / 토에이 애니메이션 / BANDAI 및 각 권리자. 코드는 MIT 라이선스이며, 외부 이미지·문구·데이터·상표의 권리는 별도입니다. 출처 표시는 이용 허가나 공식 제휴를 의미하지 않습니다.',original:'원본 프로젝트 ↗',screensNote:'화면은 가상 샘플 데이터로 구성했습니다. 이 페이지에는 분석 도구나 추적 쿠키가 없습니다.',homeAlt:'아구몬과 진화 진행률, 토큰 사용량을 보여주는 영문 앱 홈 화면',notebookAlt:'성장 단계별 필터와 수집 수를 보여주는 노트북 화면',detailAlt:'영문 설명, 필살기와 진화 조건이 있는 워그레이몬 상세 화면',videoLabel:'오메가몬 융합 연출'
 }
};
let language = 'en';
function setLanguage(next) {
 language = next === 'ko' ? 'ko' : 'en';
 const text = copy[language];
 document.documentElement.lang = language;
 document.querySelectorAll('[data-i18n]').forEach(node => { node.textContent = text[node.dataset.i18n] ?? copy.en[node.dataset.i18n]; });
 document.querySelectorAll('[data-lang]').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.lang === language)));
 document.querySelector('.home-screen').alt = text.homeAlt;
 document.querySelector('.showcase-images img').alt = text.notebookAlt;
 document.querySelector('.detail-screen').alt = text.detailAlt;
 document.querySelector('video').setAttribute('aria-label', text.videoLabel);
 document.getElementById('install-guide').href = language === 'ko' ? 'https://github.com/Choisiz/DigiMonTokenBar/blob/main/README.ko.md#다운로드설치' : 'https://github.com/Choisiz/DigiMonTokenBar#install';
 document.getElementById('windows-guide').href = language === 'ko' ? 'https://github.com/Choisiz/DigiMonTokenBar/blob/main/README.ko.md#windows-다운로드-및-사용법' : 'https://github.com/Choisiz/DigiMonTokenBar#windows-download-and-usage';
 document.getElementById('copy-status').textContent = '';
 try { localStorage.setItem('digitokenbar-language', language); } catch {}
}
let preferred;
try { preferred = localStorage.getItem('digitokenbar-language'); } catch {}
const requested = new URLSearchParams(location.search).get('lang');
setLanguage(requested === 'ko' || requested === 'en' ? requested : preferred === 'ko' || preferred === 'en' ? preferred : navigator.language.toLowerCase().startsWith('ko') ? 'ko' : 'en');
document.querySelectorAll('[data-lang]').forEach(button => button.addEventListener('click', () => setLanguage(button.dataset.lang)));
document.getElementById('copy-command').addEventListener('click', async () => {
 const text = copy[language];
 try {
  await navigator.clipboard.writeText('brew install --cask choisiz/tap/digitokenbar');
  document.getElementById('copy-command').textContent = text.copied;
  document.getElementById('copy-status').textContent = text.copySuccess;
 } catch { document.getElementById('copy-status').textContent = text.copyFailed; }
});
