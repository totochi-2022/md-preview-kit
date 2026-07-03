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
- `sample.md` … 動作確認用デモ（`,,V` で開く）

## 新マシンでの導入
```sh
bash ~/.config/nvim/vivify/install.sh
```
前提: `node`(mise), `ghq`, passwordless sudo(zip 用)。

## なぜパッチが要るか（WSL mirrored 限定の地雷）
`networkingMode=mirrored` の WSL2 では**未使用ポートへの接続が ECONNREFUSED を返さずハング**する。
Vivify は起動時 `http.get(localhost:31622/health)` で既存サーバを調べ「error なら自分が listen」する
設計のため、このプローブが固まると起動できない。パッチで 500ms タイムアウト→自前 listen にフォールバック。
（NAT モード/通常 Linux では stock の release でも動くが、パッチ版は両対応。）

## nvim 側
`lua/plugins/misc.lua`（vivify.vim spec: `ft=markdown`）、`lua/21_keymap.lua`（`,,V` → `:Vivify`）。
追従(スクロール同期)は vivify.vim の autocmd が md 進入時に curl POST する仕組み。

## 経緯
トラブルシューティング全記録は howm 日記 `2026-07-03-1657-chiikawa.md` を参照。
