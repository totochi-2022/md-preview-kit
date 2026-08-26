# md-preview-kit

Markdown のコードフェンスを図として描画するレンダラ群と、各エディタ用のアダプタ。

````markdown
```wavedrom
{ signal: [{ name: "clk", wave: "p......" }] }
```
````

と書くと、プレビュー上でタイミング図になる。描画は**すべてブラウザ側**で走るので、
サーバもヘッドレスレンダリングも要らない。

**フェンスの中身はデータ（JSON5）として解釈するだけで、実行しない。**
`eval` / `new Function` は使っていない（同種の実装で任意コード実行の脆弱性報告が
出ているため）。他人に md を配って開かせても安全な範囲に閉じてある。

## 対応しているフェンス

| 言語名 | 描画されるもの | 実装 |
|---|---|---|
| `wavedrom` | タイミング図 | `scripts/renderers/wavedrom.js`（WaveDrom） |
| `chart` | グラフ | `scripts/renderers/chart.js`（Chart.js） |
| `kvlist` | ラダー図（KV ニーモニック）＋同一デバイスのホバー相互ハイライト | `scripts/ladder.glue.js` |

`.drawio.svg` / `.fig.svg`（schemdraw）は**ただの SVG 画像**なので `![](...)` で貼れば
どのホストでも表示される（グルー不要）。mermaid はホスト側の機能に任せている。

**書き方の全体像と対応状況は [`sample.md`](sample.md) が正本**。基本の Markdown 記法から
各図の書式・書けないものまで1ファイルにまとまっているので、これをプレビューで開けば
仕様が分かる。AI に書かせるときも、このファイルを読ませれば済む。

## 構成

```
scripts/                       レンダラの正本（ホストを知らない）
  core.js                      契約と描画ディスパッチ
  renderers/wavedrom.js
  renderers/chart.js
  ladder.glue.js               ラダー図。ビルド生成物（後述）
  wavedrom.min.js              vendored
  wavedrom-skin-default.js     vendored
  chart.umd.js                 vendored
  json5.min.js                 vendored
adapters/
  vivify/config.json           Vivify 用の設定
  vivify/shim.js               Vivify 固有の処理（更新検出・エラーブリッジ）
  vscode/package.json          VS Code 拡張の宣言（previewScripts）
  vscode/sync.sh               scripts/ → media/ の同期（生成）
  vscode/build.sh              .vsix と配布 zip を作る
  vscode/dist-files/           配布物に同梱するもの（install.bat 等。UTF-8 で管理）
docs/vscode-setup.md           相手が読む手順書（配布 zip の INSTALL.md になる）
docs/build-and-release.md      配る側の手順（配布物には含めない）
sample.md                      書き方の見本・仕様書・動作確認
sample.drawio.svg              sample.md が参照する図（draw.io）
sample.fig.svg                 sample.md が参照する図（schemdraw、ソース埋め込み）
```

`ladder.glue.js` は **リポジトリに持たない**。
[totochi-2022/ladder_viewer](https://github.com/totochi-2022/ladder_viewer) の
build フック（`vivify-glue.sh`）が `scripts/` に生成する。

## アダプタ

### Vivify

`~/.config/vivify/config.json` を `adapters/vivify/config.json` に symlink する。

```sh
ln -sf ~/work/md-preview-kit/adapters/vivify/config.json ~/.config/vivify/config.json
```

Vivify 本体（パッチ版のビルド手順を含む）は `nvim-config` の `vivify/` にある。
フェンスの言語名を class に残すためのパーサパッチが要る（`<pre class="language-wavedrom">`）。

### VS Code

組み込み Markdown プレビューに `markdown.previewScripts` で `scripts/` を差し込む拡張。
ビルド不要（宣言だけの拡張）。**wavedrom / chart / kvlist すべて動く。**

Windows の相手に渡す配布物は1コマンドで作れる。

```sh
sh adapters/vscode/build.sh
# → dist/md-preview-kit-<ver>.zip   ★これを渡す
```

zip を解凍して **`install.bat` をダブルクリックすれば導入完了**（相手側に WSL・`sh`・
Node.js は要らない）。中身は vsix・`install.bat`・`はじめに読む.txt`・`INSTALL.md`・
サンプル一式。

- **相手が読む手順書**: [`docs/vscode-setup.md`](docs/vscode-setup.md)（→ zip 内 `INSTALL.md`）
- **配る側の手順**: [`docs/build-and-release.md`](docs/build-and-release.md)

VS Code 側の制約が設計の基準になっている（厳しい方に合わせれば Vivify でも通るため）:

- **CSP `script-src 'nonce-...'`** — `eval` / `new Function` は使えない（→ JSON5 で回避）。
  レンダリング済み HTML への `<script>` 注入も不可（nonce を取得する手段が無い）
- **`previewScripts` は非同期・順不同に読み込まれる** — レンダラは依存ライブラリを
  `register(lang, render, { needs: [...] })` で宣言し、core が揃うまで描画を遅らせる。
  特に WaveDrom は WaveSkin 未読込だと例外を投げず空の図を描くため、この待ち合わせが要る。
- **再描画は `vscode.markdown.updateContent` イベント**（VS Code 1.63 以降、
  プレビューが差分 DOM 更新になったため。スクリプトは初回に1度だけ初期化される）
- **フェンスの class 位置がホストで違う**: VS Code は `<pre><code class="language-X">`、
  Vivify は `<pre class="language-X">`。core が両方を拾う。
- WSL のファイルを UNC 経由で開くと VS Code のファイル監視が効かず、保存してもプレビューが
  自動更新されない（VS Code 側の既知の制約）。

## ライセンス

自作コードのみで構成されている。Vivify 本体（GPL-3.0）とそのパッチはこのリポジトリに含めない。
`scripts/*.min.js` 等の vendored ライブラリは各々の元ライセンスに従う。
