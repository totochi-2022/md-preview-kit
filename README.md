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

### VS Code（予定）

`markdown.previewScripts` で `scripts/` を組み込みプレビューに差し込む。
VS Code の markdown-it は最初から `language-*` class を吐くのでパッチは不要。

VS Code 側の制約が設計の基準になる（厳しい方に合わせれば Vivify でも通るため）:

- **CSP `script-src 'nonce-...'`** — `eval` / `new Function` は使えない。
  レンダリング済み HTML への `<script>` 注入も不可（nonce を取得する手段が無い）
- **再描画は `vscode.markdown.updateContent` イベント**（VS Code 1.63 以降、
  プレビューが差分 DOM 更新になったため。スクリプトは初回に1度だけ初期化される）

## ライセンス

自作コードのみで構成されている。Vivify 本体（GPL-3.0）とそのパッチはこのリポジトリに含めない。
`scripts/*.min.js` 等の vendored ライブラリは各々の元ライセンスに従う。
