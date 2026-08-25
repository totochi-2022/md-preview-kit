# md-preview-kit

Markdown のコードフェンスを図として描画するレンダラ群と、各エディタ用のアダプタ。

````markdown
```wavedrom
{ signal: [{ name: "clk", wave: "p......" }] }
```
````

と書くと、プレビュー上でタイミング図になる。描画は**すべてブラウザ側**で走るので、
サーバもヘッドレスレンダリングも要らない。

## 対応しているフェンス

| 言語名 | 描画されるもの | 実装 |
|---|---|---|
| `wavedrom` | タイミング図 | `scripts/glue.js`（WaveDrom） |
| `chart` | グラフ | `scripts/glue.js`（Chart.js） |
| `kvlist` | ラダー図（KV ニーモニック）＋同一デバイスのホバー相互ハイライト | `scripts/ladder.glue.js` |

## 構成

```
scripts/
  glue.js                    レンダラ本体（wavedrom / chart）
  ladder.glue.js             ラダー図。ビルド生成物（後述）
  wavedrom.min.js            vendored
  wavedrom-skin-default.js   vendored
  chart.umd.js               vendored
adapters/
  vivify/config.json         Vivify 用の設定
sample.md                    動作確認用デモ
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
ビルド不要（宣言だけの拡張）。

```sh
sh adapters/vscode/sync.sh            # scripts/ を media/ にコピー（生成物）
cd adapters/vscode
npx @vscode/vsce package --allow-missing-repository --skip-license
code --install-extension md-preview-kit-*.vsix --force
```

導入後、md を開いて Ctrl+Shift+V でプレビュー。ラダー（kvlist）はまだ未対応。

VS Code 側の制約が設計の基準になっている（厳しい方に合わせれば Vivify でも通るため）:

- **CSP `script-src 'nonce-...'`** — `eval` / `new Function` は使えない（→ JSON5 で回避）。
  レンダリング済み HTML への `<script>` 注入も不可（nonce を取得する手段が無い）
- **`previewScripts` は非同期・順不同に読み込まれる** — レンダラは依存ライブラリを
  `register(lang, fn, { needs: [...] })` で宣言し、core が揃うまで描画を遅らせる。
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
