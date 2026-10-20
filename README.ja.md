# DigiTokenBar

**AIコーディングのトークン使用量で、macOSメニューバーのデジモンを育てるファンアプリ。**

[English](README.md) · [한국어](README.ko.md) · **日本語**

[chattymin/PokeTokenBar](https://github.com/chattymin/PokeTokenBar) を基にした、非公式・非商用目的のファンプロジェクトです。
Claude Code、Codexなどのローカル使用記録を読み、孵化・分岐進化・合体・収集につなげます。
原作者と貢献者のMITライセンス表示・Git履歴を維持しています。

## 機能

- 475種のデジモン、Time Stranger基準の番号・進化関係、Notebook。
- 未収集候補を優先する通常進化、収集済み素材による合体、消費アイテム・当日トークンによる特殊進化。
- 特殊進化は現在の育成個体を置き換えず、Notebookに登録します。
- 育成中1体＋保管1体。保管中は成長せず、最終形態のゲージ100%で保管個体へ自動復帰します。
- タマゴ状態から新たな継続育成は開始できません。保管個体がなければ育成完了後に新しいタマゴになります。
- 黒と水色のデジタルUI、使用量・入出力・キャッシュ・費用表示。

外部のデジモン・アイテム画像はアプリに同梱せず、必要時にダウンロードしてMacにキャッシュします。
カプセルは背景付きの原画像を使用します。初回はインターネット接続が必要です。
生成したX抗体画像とアプリアイコン、図鑑データ・説明文の抜粋は同梱します。

## インストール

**macOS 14以上・Apple Silicon Mac**が必要です。Xcodeや有料開発者アカウントは不要です。

### Homebrew

[Homebrew](https://brew.sh)がインストールされていれば、次のコマンドで導入できます。

```sh
brew install --cask choisiz/tap/digitokenbar
```

チェックサムは自動確認されます。アプリケーションフォルダから **DigiTokenBar** を開いてください。
更新時はアプリを終了して `brew update`、`brew upgrade --cask choisiz/tap/digitokenbar` を実行します。

### 直接ダウンロード

1. [ZIPをダウンロード](https://github.com/Choisiz/DigiTokenBar/releases/download/v0.1.0/DigiTokenBar-0.1.0-macos-arm64.zip)します。
2. 展開した **DigiTokenBar.app** をアプリケーションフォルダへ移動します。
3. アプリを開くとメニューバーに表示されます。

直接インストールした場合は、アプリを終了して新しいファイルに置き換えます。
どちらの方法でも育成データは保持されます。初回画像表示にはインターネット接続が必要です。

### 初回起動

Developer ID署名・Apple公証はありません。信頼できるダウンロードがブロックされた場合は、
[Appleの案内](https://support.apple.com/ja-jp/102445)に従い「プライバシーとセキュリティ」から実行を許可してください。
管理対象Macでは許可できない場合があります。システム全体の保護を無効化しないでください。

<details>
<summary>任意：直接ダウンロードのチェックサム確認</summary>

[Releases](https://github.com/Choisiz/DigiTokenBar/releases)から対応する `.sha256` ファイルも取得し、同じフォルダで実行します。
通常のインストールには必須ではありません。Homebrewでは自動確認されます。

```sh
shasum -a 256 -c DigiTokenBar-0.1.0-macos-arm64.zip.sha256
```

</details>

## ビルド

macOS 14以上とSwift 6が必要です。現在のローカル配布候補はApple Siliconで検証します。
Intel、Universal、Developer ID署名、Apple公証は未検証／未完了です。

```sh
git clone https://github.com/Choisiz/DigiTokenBar.git
cd DigiTokenBar
./scripts/build-digimon-app.sh
open build/DigiTokenBar.app
```

署名はad-hocです。Gatekeeper承認や公証を意味しません。公開ZIPはReleasesから取得できます。Homebrewにも対応しています。App Store配布・アプリ内自動更新は提供していません。
詳細は[英語README](README.md)と[検証状況](docs/reference/distribution-validation.md)をご覧ください。
画面・プロフィールの日本語ローカライズが完全であるとは保証しません。

## 権利と出典

**MITはソースコードに適用されます。第三者の画像・文章・商標・データの権利は別です。**
現在のローカル版にはデジモン関連素材が含まれ、再配布許諾は確認できていません。
出典表示や非商用目的だけで許諾が成立するわけではありません。

デジモンの名称・キャラクター・デザインなどは、BANDAI、Akiyoshi Hongo、Toei Animation、
Bandai Namco Entertainmentなど各権利者に帰属します。公式・公認・提携アプリではありません。
ファンアイコンもデジヴァイスのデザインを基にしています。

[NOTICE](NOTICE.md) · [第三者素材の出典と権利状況](THIRD_PARTY_NOTICES.md) · [LICENSE](LICENSE)
