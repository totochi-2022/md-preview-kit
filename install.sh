#!/usr/bin/env bash
# install.sh — WSL mirrored 対応パッチ版 Vivify を各マシンへ導入する
#
# なぜパッチが要るか:
#   WSL2 の networking=mirrored では「未使用ポートへの接続が ECONNREFUSED を
#   返さずハング」する。Vivify は起動時に http.get(localhost/health) で既存
#   サーバの有無を調べ、error(接続拒否)なら自分が listen する設計なので、
#   このプローブがハングすると server.listen に到達せず起動できない。
#   → src/app.ts のプローブに 500ms タイムアウトを足す(app.ts.patch)。
#
# 何をするか:
#   1. 上流 Vivify を ghq clone
#   2. app.ts.patch を適用(冪等)
#   3. SEA バイナリをビルド → viv / vivify-server を ~/.local/bin へ
#   4. ~/.config/vivify/config.json をこのディレクトリの config.json に symlink
#
# 前提: node(mise 等), ghq, passwordless sudo(zip 導入用)。
# 補足: NAT モードWSL / 通常 Linux なら stock の release でも動く(パッチ不要)が、
#       パッチ版は両対応なのでこれで統一してよい。
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://github.com/jannis-baum/Vivify"
BIN_DIR="$HOME/.local/bin"

echo "[1/5] 依存確認"
command -v node >/dev/null || { echo "!! node が無い。mise 等で導入してから再実行"; exit 1; }
command -v ghq  >/dev/null || { echo "!! ghq が無い"; exit 1; }
command -v zip  >/dev/null || sudo apt-get install -y zip
corepack enable >/dev/null 2>&1 || true

echo "[2/5] clone (ghq)"
ghq get "$REPO_URL" >/dev/null 2>&1 || true
VDIR="$(ghq list --full-path | grep -iE 'jannis-baum/Vivify$' | head -1)"
[ -n "$VDIR" ] || { echo "!! clone 失敗"; exit 1; }
cd "$VDIR"

echo "[3/5] パッチ適用(冪等: 一旦戻してから当てる)"
git checkout -- src/app.ts src/parser/highlight.ts 2>/dev/null || true
git apply "$HERE/vivify.patch"

echo "[4/5] ビルド & install (webpack+SEA で数分)"
yarn install
./configure "$BIN_DIR"
# 重要: static/ は node_modules への symlink を含む。古い/不完全な static.zip が
# あると vendor(mermaid/katex/clipboard)が欠落するので必ず消してから作り直す。
rm -f build/static.zip build/linux/vivify-server
make linux
make install

echo "[5/6] config 設置 (~/.config/vivify/config.json → 本ディレクトリ)"
mkdir -p "$HOME/.config/vivify"
ln -sf "$HERE/config.json" "$HOME/.config/vivify/config.json"

echo "[6/6] figure studio 依存"
# 図生成: schemdraw / matplotlib（Python→SVG）
if command -v python3 >/dev/null; then
    python3 -m pip install --quiet streamlit schemdraw matplotlib \
        && echo "  py: streamlit/schemdraw/matplotlib OK" \
        || echo "  △ py 失敗。手動: pip install streamlit schemdraw matplotlib"
else
    echo "  △ python3 が無いので図依存スキップ（python 用意後に pip install）"
fi
# studio ページの左ペイン: ttyd(ブラウザ端末) + tmux(nvim 永続化)。nvim をそのまま
# 埋めるので pyright 補完が効く。tmux 永続化でブラウザ/ttyd が落ちても編集状態は残る。
command -v ttyd >/dev/null || sudo apt-get install -y ttyd
command -v tmux >/dev/null || sudo apt-get install -y tmux
echo "  ttyd/tmux: $(command -v ttyd >/dev/null && echo OK || echo 未) / $(command -v tmux >/dev/null && echo OK || echo 未)"

echo "--- 起動確認 ---"
"$BIN_DIR/vivify-server" >/dev/null 2>&1 &
SVPID=$!
ok=""
for _ in 1 2 3 4 5 6; do
    sleep 1
    [ "$(curl -s -m3 -o /dev/null -w '%{http_code}' http://localhost:31622/health 2>/dev/null)" = "200" ] && { ok=1; break; }
done
kill "$SVPID" 2>/dev/null || true
if [ -n "$ok" ]; then
    echo "✓ 完了: $(command -v viv) / サーバ listen 31622 OK"
else
    echo "△ ビルドは通ったが起動未確認。手動で 'viv <file.md>' を試すこと"
fi
