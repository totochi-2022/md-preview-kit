#!/bin/sh
# 配布物を1発で作る: media/ 同期 → .vsix ビルド → Windows 向け配布 zip を dist/ に出力。
#
#   sh adapters/vscode/build.sh
#
# 出来上がるもの（いずれも生成物・git 管理外）:
#   dist/md-preview-kit-<ver>.zip               ★相手に渡すのはこれ
#   adapters/vscode/md-preview-kit-<ver>.vsix   拡張だけ渡したい場合
#
# 配布 zip は Windows で解凍して install.bat をダブルクリックするだけで済む構成。
# 相手側に WSL・sh・Node.js は要らない（このスクリプトを動かすのは配る側だけ）。
set -eu
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)

# 1. レンダラ(正本は root/scripts)を拡張配下へコピー
sh "$here/sync.sh" >/dev/null
echo "1/4 media/ を同期した"

# 2. LICENSE は vsix に同梱したいがリポジトリ上の正本は root にあるのでコピー(生成物)
cp "$root/LICENSE" "$here/LICENSE"

# 3. .vsix をビルド
rm -f "$here"/*.vsix
(cd "$here" && npx --yes @vscode/vsce package >/dev/null)
vsix=$(ls "$here"/*.vsix | head -1)
ver=$(basename "$vsix" .vsix | sed 's/^md-preview-kit-//')
echo "2/4 $(basename "$vsix") をビルドした ($(du -h "$vsix" | cut -f1))"

# 4. 配布物を並べる
stage="$root/dist/md-preview-kit-$ver"
rm -rf "$root/dist"
mkdir -p "$stage"
cp "$vsix" "$stage/"
cp "$root/docs/vscode-setup.md" "$stage/INSTALL.md"
cp "$root/sample.md" "$stage/"
cp "$root/sample.drawio.svg" "$stage/"
cp "$root/sample.fig.svg" "$stage/"

# install.bat: 日本語 Windows の cmd は既定 CP932 なので変換して置く。改行も CRLF に。
iconv -f UTF-8 -t CP932 "$here/dist-files/install.bat" | sed 's/$/\r/' > "$stage/install.bat"
# 最初に読む案内: メモ帳でもエディタでも確実に読めるよう UTF-8 BOM + CRLF。
{ printf '\357\273\277'; sed 's/$/\r/' "$here/dist-files/README-first.txt"; } > "$stage/はじめに読む.txt"
echo "3/4 dist/ に配布物を並べた (install.bat は CP932+CRLF に変換)"

# 5. zip: 日本語ファイル名を Windows のエクスプローラで正しく展開させるには
#    UTF-8 フラグ(EFS, 0x800)が必要。zip(1) はこれを立てないので python の zipfile で作る。
zip="$root/dist/md-preview-kit-$ver.zip"
python3 - "$zip" "$stage" <<'PYEOF'
import os, sys, zipfile
zip_path, stage = sys.argv[1], sys.argv[2]
base = os.path.dirname(stage)
with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as z:
    for dirpath, _, files in os.walk(stage):
        for name in sorted(files):
            full = os.path.join(dirpath, name)
            z.write(full, os.path.relpath(full, base))
# 書き出し後に読み直して、非 ASCII 名に UTF-8 フラグが立っていることを確認する
# (フラグはシリアライズ時に付くので、書き込み中の infolist では判定できない)
with zipfile.ZipFile(zip_path) as z:
    for info in z.infolist():
        if not info.filename.isascii() and not (info.flag_bits & 0x800):
            sys.exit('UTF-8 フラグが立っていない: ' + info.filename)
PYEOF
rm -rf "$stage"
echo "4/4 $(basename "$zip") ($(du -h "$zip" | cut -f1))"
echo
echo "→ この zip を相手に渡す。解凍して install.bat をダブルクリックで入る。"
