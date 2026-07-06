# vivify/ — Vivify プレビュー環境の再現用一式

md をレポート化する計画（グラフ/回路図/タイミング図）の閲覧側に Vivify を使う。
本体 `viv`/`vivify-server` はリポ管理外（各マシンでビルド）なので、ここに**再現手順一式**を置く。

## ファイル
- `install.sh` … 上流 clone → パッチ → SEA ビルド → `~/.local/bin` 導入 → config symlink
- `vivify.patch` … 上流への2点パッチ:
  - `src/app.ts`: 起動時 `/health` プローブに 500ms タイムアウト(mirrored 対策)
  - `src/parser/highlight.ts`: 未知言語フェンスの class に元言語名を残す
    (`<pre class="language-wavedrom">` 等。glue が種別検出できるように)
- `config.json` … Vivify 設定(browserOptions/timeout/scripts)。`~/.config/vivify/config.json` はこれへの symlink
- `scripts/` … `config.json` の `scripts` で読み込む描画グルー一式:
  - `wavedrom.min.js` + `wavedrom-skin-default.js`(vendored)
  - `chart.umd.js`(vendored)
  - `glue.js` … `pre.language-wavedrom`/`pre.language-chart` を WaveDrom/Chart で描画。
    `MutationObserver` で ws 更新にも追従
- `render/render_schemdraw.py` … `render(source)`: Python スニペット→SVG化。namespace に `out`(SVGパス)
  を渡し、ソースが `out` に SVG を書けば何でも可(schemdraw/matplotlib/pygal/drawsvg…)。元ソースを
  `<metadata id="diagram-source" data-type="python">` に埋込(draw.io 方式 round-trip)。CLI/import 両用。
- `render/studio.py` … Streamlit 製 figure studio（左=ソース(Ace ハイライト)/右=ライブSVG/📋コピー/💾保存）。
  テンプレ(schemdraw/matplotlib/raw SVG)。`?svg=<path>` で既存の埋込ソースを読込。
- `sample.md` … 動作確認用デモ（`,,V` で開く）

## 新マシンでの導入
```sh
bash ~/.config/nvim/vivify/install.sh
```
前提: `node`(mise), `ghq`, passwordless sudo(zip 用)。figure studio 用に pip(streamlit / streamlit-ace / schemdraw / matplotlib)も導入。

## なぜパッチが要るか（WSL mirrored 限定の地雷）
`networkingMode=mirrored` の WSL2 では**未使用ポートへの接続が ECONNREFUSED を返さずハング**する。
Vivify は起動時 `http.get(localhost:31622/health)` で既存サーバを調べ「error なら自分が listen」する
設計のため、このプローブが固まると起動できない。パッチで 500ms タイムアウト→自前 listen にフォールバック。
（NAT モード/通常 Linux では stock の release でも動くが、パッチ版は両対応。）

## nvim 側
- `lua/vivify.lua` … `,,V` デュアルモード（web=右ペイン / 端末=ブラウザタブ）
- `lua/21_keymap.lua`（`,,V` → `require("vivify").open()`）、`lua/plugins/misc.lua`（vivify.vim spec: `ft=markdown`）
- 追従(スクロール同期)は vivify.vim の autocmd が md 進入時に curl POST する仕組み。
- `lua/diagram.lua` … 図は **figure studio(Python→SVG)** で作成/編集。SVG 固定・ソース埋込で統一。
  - **`:Studio`**: studio を新規で起動 → 書く → 「📋 SVGコピー」→ md で `,,p`(貼付)。
  - **`,,e`(OpenDrawio)**: `![](x.svg)` 上で、SVG に `<metadata id="diagram-source">` があれば
    studio を `?svg=` で起動(埋込ソース復元)→ 保存で上書き。draw.io SVG(`content="<mxfile>"`)→ draw.io.exe。
  - **`,,p`(SmartPaste)**: クリップボードの SVG を保存＋`![]`挿入（studio コピー/draw.io コピー共通）。
  - studio(streamlit)は **8501**。未起動なら起動し、ブラウザは wslview。判別は拡張子でなく埋込マーカー
    （draw.io=`content=mxfile` / studio=`diagram-source` で別物）。旧 fence(`:DiagramRender`)は撤去。

## 経緯
howm 日記: `2026-07-03-1657-chiikawa.md`（Vivify 導入・トラブル全記録）、
`2026-07-06-1049-chiikawa.md`（標準ビューア化・figure studio）。
