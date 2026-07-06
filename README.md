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
- `render/render_schemdraw.py` … schemdraw スニペット(案A)→SVG化。`<metadata data-type="schemdraw">`
  に元ソースを埋め込む(draw.io 方式の round-trip)。SVGバックエンドで matplotlib 不要。
- `sample.md` … 動作確認用デモ（`,,V` で開く）

## 新マシンでの導入
```sh
bash ~/.config/nvim/vivify/install.sh
```
前提: `node`(mise), `ghq`, passwordless sudo(zip 用)。schemdraw も pip 導入する(回路図用)。

## なぜパッチが要るか（WSL mirrored 限定の地雷）
`networkingMode=mirrored` の WSL2 では**未使用ポートへの接続が ECONNREFUSED を返さずハング**する。
Vivify は起動時 `http.get(localhost:31622/health)` で既存サーバを調べ「error なら自分が listen」する
設計のため、このプローブが固まると起動できない。パッチで 500ms タイムアウト→自前 listen にフォールバック。
（NAT モード/通常 Linux では stock の release でも動くが、パッチ版は両対応。）

## nvim 側
- `lua/vivify.lua` … `,,V` デュアルモード（web=右ペイン / 端末=ブラウザタブ）
- `lua/21_keymap.lua`（`,,V` → `require("vivify").open()`）、`lua/plugins/misc.lua`（vivify.vim spec: `ft=markdown`）
- 追従(スクロール同期)は vivify.vim の autocmd が md 進入時に curl POST する仕組み。
- `lua/diagram.lua` … 回路図(schemdraw)の事前SVG化＋round-trip編集。
  - **`:DiagramRender`**: バッファ内の**全** ` ```schemdraw ` フェンス→SVG化→`![](assets/xxx.svg)` 置換
    （カーソル位置無関係。ソースは SVG の `<metadata data-type>` へ埋込）。ファイル名は**内容ハッシュ**
    なので同内容なら同名＝上書き（再実行/auto描画で増殖しない）。
  - **auto**: `,,V`(ビュー)時に自動で全フェンス描画。無効化は `vim.g.diagram_autorender = false`。
  - **`:DiagramEdit`**: `![](x.svg)` の埋込ソースを復元しスクラッチ編集、`:w` で同じ SVG 再生成
  - 判別は拡張子でなく**埋込マーカー＋type**（draw.io 方式）。回路図(python)はライブ描画不可なので事前SVG。
  - **既存の draw.io 統合(`,,p` SmartPaste / `,,e` OpenDrawio)に相乗り**: `,,p` はフェンス内なら
    DiagramRender・でなければ従来の貼付、`,,e` は埋込ソース付きSVGなら nvim エディタ・でなければ draw.io。
    → draw.io と schemdraw を同じキーで共通操作。

## 経緯
トラブルシューティング全記録は howm 日記 `2026-07-03-1657-chiikawa.md` を参照。
