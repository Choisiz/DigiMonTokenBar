# DigiMonTokenBar website

A static English/Korean introduction and download page, deployed at
https://choisiz.github.io/DigiMonTokenBar/ through `.github/workflows/pages.yml`.

Build: `python3 site/build.py`. Preview `build/pages-preview/` with a local HTTP server.
The assembler copies an explicit public allowlist; it never copies saves or the rest
of the build directory. Version and direct-download links follow the macOS build script.
Edit page copy in `app.js`, layout in `styles.css`, and structure in `index.html`.

App screenshots use synthetic sample data. `fusion-demo.mp4` is a 17-second rendering
of the production fusion scene, without personal usage records. Character artwork,
profile text and designs retain their respective owners' rights; see
[third-party notices](../THIRD_PARTY_NOTICES.md). This is an unofficial fan project,
based on [PokeTokenBar](https://github.com/chattymin/PokeTokenBar).

Relevant main-branch changes deploy automatically. For a commit marked `[skip ci]`,
run the **Deploy website** workflow manually. Website-only changes do not require
rebuilding or releasing the macOS app.
