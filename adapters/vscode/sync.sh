#!/bin/sh
# scripts/ を拡張の media/ へコピーする。
#
# レンダラの正本は常に ../../scripts/。拡張に同梱するには物理的に配下へ
# 置く必要がある(previewScripts のパスは拡張ルート相対)ため、コピーで同期する。
# media/ は生成物なので git 管理しない。
#
# 使い方: sh adapters/vscode/sync.sh
set -eu
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
media="$here/media"

rm -rf "$media"
mkdir -p "$media/renderers"

for f in json5.min.js wavedrom.min.js wavedrom-skin-default.js chart.umd.js core.js; do
    cp "$root/scripts/$f" "$media/$f"
done
cp "$root/scripts/renderers/wavedrom.js" "$media/renderers/wavedrom.js"
cp "$root/scripts/renderers/chart.js"    "$media/renderers/chart.js"

# ladder.glue.js は ladder_viewer の生成物。previewScripts に常に載せてあるので、
# 無い環境では VS Code が file-not-found を出さないよう no-op スタブを置く。
# 生成するには: sh ~/work/ladder_viewer/vivify-glue.sh
if [ -f "$root/scripts/ladder.glue.js" ]; then
    cp "$root/scripts/ladder.glue.js" "$media/ladder.glue.js"
else
    echo "// ladder.glue.js 未生成 (sh ~/work/ladder_viewer/vivify-glue.sh)" > "$media/ladder.glue.js"
    echo "  ! ladder.glue.js が無いのでスタブを置いた（ladder は無効）" >&2
fi

# sourcemap 参照を剥がす: webview の CSP は default-src \'none\' なので .map の取得が
# ブロックされ、Console に無関係な警告が出続ける。配布物には不要。
find "$media" -name '*.js' -exec sed -i -E '/^\/\/# sourceMappingURL=/d; s@/[*]# sourceMappingURL=[^*]*[*]/@@g' {} +

echo "synced -> $media"
ls -1 "$media" "$media/renderers"
