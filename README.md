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
  - `ladder.glue.js` … `pre.language-kvlist`(KVニーモニック)をラダー図SVGに描画＋
    ホバーで同一デバイスをクロスリファレンスハイライト。**生成物なので直接編集しない**
    (ソースは `~/work/ladder_viewer/ladder-core.mjs`、再生成は `sh ~/work/ladder_viewer/vivify-glue.sh`)
- `render/render_schemdraw.py` … Python スニペット→画像化。namespace に `out`(出力パス)を渡し、
  ソースが `out` に保存すれば何でも可。**出力拡張子で形式判定(svg/png/jpg)**。元ソースを埋込:
  SVG=`<metadata>` / PNG=tEXt チャンク / JPEG=COM コメント(draw.io 方式 round-trip)。
  `--extract <file>` で埋込ソースを取り出す(svg/png/jpg 共通・`,,e` の判別に使用)。png/jpg は Pillow 使用。
- `render/studio.py` … Streamlit 製 figure studio。**左=vim(ttyd の nvim)/右=ライブSVG(白ボックス)**、
  上部ツールバー(テンプレ挿入/📋SVGコピー)。`?svg=&py=&ttyd=&sock=` を受け取り、左に ttyd(nvim)を
  iframe で、右は `st.fragment(run_every="1s")` で SVG を読み直して表示(`:w` で更新・端末は再描画しない)。
  生成エラー時(=`<py>.err` が在る)は画像も📋コピーも出さずエラーだけ表示(古い画像を残さない)。
  テンプレ挿入は `?py=` を書き換え **nvim RPC(`--remote-expr 'execute("edit! | write")'`)** でリロード
  (tmux send-keys は noice の cmdline ポップアップにキーを取りこぼすため不可)。
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
- `lua/diagram.lua` … 図は **figure studio(左=nvim/右=SVG)** で作成/編集。SVG 固定・ソース埋込で統一。
  補完のためソース部を Ace でなく本物の nvim(ttyd+tmux, pyright)にした。
  - **`:Studio [schemdraw|matplotlib|raw] [svg|png]`**: 現 md/typst の `assets/` に `<ts>.fig.<fmt>` を
    作りリンク挿入(既定 svg) → temp `.py` を作り studio を開く。左=nvim で編集 → **`:w`** で再生成
    (BufWritePost)→ 右が更新。svg が図の主役、png は matplotlib 等の raster 向き。
  - **`,,e`(OpenDrawio)**: `![](x.svg)` 上で `<metadata id="diagram-source">` があれば埋込ソースを復元して
    studio で編集 → `:w` で上書き。draw.io SVG(`content="<mxfile>"`)→ draw.io.exe。
  - 構成: ttyd(**7690**, tmux セッション `figstudio` で nvim 永続化) / Streamlit(**8501**) / Vivify(**31622**)。
    Streamlit がツールバー+2ペインを描画、左は ttyd iframe、右は Vivify iframe。tmux 永続化で
    ブラウザ/ttyd が落ちても編集状態は残る。同時に1図(固定ポート)。
  - **`,,p`(SmartPaste)**: クリップボードの SVG/draw.io を保存＋`![]`挿入（外部からの貼付用）。

## 経緯
howm 日記: `2026-07-03-1657-chiikawa.md`（Vivify 導入・トラブル全記録）、
`2026-07-06-1049-chiikawa.md`（標準ビューア化・figure studio）。
