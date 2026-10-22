# DigiMonTokenBar

プロジェクト名は **DigiMonTokenBar** に変更しました。互換性のため、現在のアプリ名 `DigiTokenBar.app`、Homebrew cask `digitokenbar`、既存の保存先は維持します。

[**紹介サイト ↗**](https://choisiz.github.io/DigiMonTokenBar/)

**AIコーディングのトークン使用量で、macOSメニューバーのデジモンを育てるファンアプリ。**

[English](README.md) · [한국어](README.ko.md) · **日本語**

[chattymin/PokeTokenBar](https://github.com/chattymin/PokeTokenBar) を基にした、非公式・非商用目的のファンプロジェクトです。
Claude Code、Codexなどのローカル使用記録を読み、孵化・分岐進化・合体・収集につなげます。
原作者と貢献者のMITライセンス表示・Git履歴を維持しています。

## 0.1.1 の更新

特殊進化の演出・通知・アイテム条件と475種のプロフィール抜粋・必殺技が英語設定に対応しました。

## 画面で見る機能

実際の製品UIを、英語・架空のサンプルデータでレンダリングした画像です。個人の利用記録や新しいモックアップではありません。キャラクター・アイテム画像の権利は各権利者に帰属します。[出典・権利の案内](THIRD_PARTY_NOTICES.md)をご確認ください。

<table>
<tr>
<td width="45%" align="center"><img src="assets/readme-screenshots/home.png" width="280" alt="コーディングで育つパートナー"></td>
<td width="55%"><h3>コーディングで育つパートナー</h3><p>当日のトークンと成長ゲージを確認し、Codex・Claude Codeを切り替えます。特殊進化の準備ができると、オレンジ色の電球から候補を開けます。</p></td>
</tr>
<tr>
<td width="45%" align="center"><img src="assets/readme-screenshots/notebook.png" width="280" alt="475種を集めるNotebook"></td>
<td width="55%"><h3>475種を集めるNotebook</h3><p>収集数を確認し、成長段階で絞り込み、名前やTime Stranger番号で検索できます。ページを切り替えてコレクションを眺めましょう。</p></td>
</tr>
<tr>
<td width="45%" align="center"><img src="assets/readme-screenshots/detail.png" width="280" alt="デジモンを詳しく知る"></td>
<td width="55%"><h3>デジモンを詳しく知る</h3><p>大きな画像、成長段階、公式プロフィールの抜粋、必殺技、次の進化ルートを確認できます。リンクから公式図鑑の説明を開けます。</p></td>
</tr>
<tr>
<td width="45%" align="center"><img src="assets/readme-screenshots/evolution-routes.png" width="280" alt="次の進化を選ぶ"></td>
<td width="55%"><h3>次の進化を選ぶ</h3><p>登録済みの通常候補は即時進化し、未登録候補は成長ゲージを満たします。未選択なら未収集の通常候補を優先して自動進化します。</p></td>
</tr>
<tr>
<td width="45%" align="center"><img src="assets/readme-screenshots/special-evolution.png" width="280" alt="進化条件を確認する"></td>
<td width="55%"><h3>進化条件を確認する</h3><p>電球から進化・育成の候補を開き、素材、アイテム、当日トークン条件を確認します。合体ではNotebookの収集記録を使い、素材デジモンの登録を失いません。</p></td>
</tr>
<tr>
<td width="45%" align="center"><img src="assets/readme-screenshots/fusion.png" width="280" alt="データが集まる合体演出"></td>
<td width="55%"><h3>データが集まる合体演出</h3><p>ウォーグレイモンとメタルガルルモンからオメガモンへ。データ結合、シルエット、0・1の帯、登場後の光を演出します。アイテム・特殊な通常進化はシルエットから始まります。</p></td>
</tr>
<tr>
<td width="45%" align="center"><img src="assets/readme-screenshots/shop.png" width="170" alt="Shop"><img src="assets/readme-screenshots/bag.png" width="170" alt="Bag"></td>
<td width="55%"><h3>仮想トークンで買い、バッグで使う</h3><p>タマゴ、ペンダント、デジヴァイス、X抗体、専用カプセルを購入します。バッグで数量を確認し、ペンダントを使用できます。進化アイテムは進化確定時に消費します。実際の決済はありません。</p></td>
</tr>
</table>

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

Homebrewがチェックサムを確認し、インストールしたアプリの隔離属性（`com.apple.quarantine`）のみを削除します。
Apple公証を取得したりシステム全体の保護を無効化したりする処理ではありません。
アプリケーションフォルダから **DigiTokenBar** を開いてください。
更新時はアプリを終了して `brew update`、`brew upgrade --cask choisiz/tap/digitokenbar` を実行します。

### 直接ダウンロード

1. [ZIPをダウンロード](https://github.com/Choisiz/DigiMonTokenBar/releases/download/v0.1.1/DigiTokenBar-0.1.1-macos-arm64.zip)します。
2. 展開した **DigiTokenBar.app** をアプリケーションフォルダへ移動します。
3. アプリを開くとメニューバーに表示されます。

直接インストールした場合は、アプリを終了して新しいファイルに置き換えます。
どちらの方法でも育成データは保持されます。初回画像表示にはインターネット接続が必要です。

### 直接インストール後の初回起動

Developer ID署名・Apple公証はありません。信頼できるダウンロードがブロックされた場合は、
[Appleの案内](https://support.apple.com/ja-jp/102445)に従い「プライバシーとセキュリティ」から実行を許可してください。
管理対象Macでは許可できない場合があります。システム全体の保護を無効化しないでください。

<details>
<summary>任意：直接ダウンロードのチェックサム確認</summary>

[Releases](https://github.com/Choisiz/DigiMonTokenBar/releases)から対応する `.sha256` ファイルも取得し、同じフォルダで実行します。
通常のインストールには必須ではありません。Homebrewでは自動確認されます。

```sh
shasum -a 256 -c DigiTokenBar-0.1.1-macos-arm64.zip.sha256
```

</details>

## ビルド

macOS 14以上とSwift 6が必要です。現在のローカル配布候補はApple Siliconで検証します。
Intel、Universal、Developer ID署名、Apple公証は未検証／未完了です。

```sh
git clone https://github.com/Choisiz/DigiMonTokenBar.git
cd DigiMonTokenBar
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
