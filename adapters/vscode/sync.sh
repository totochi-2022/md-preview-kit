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

# ladder.glue.js は未対応: 契約に載っておらず、自前の MutationObserver が
# Vivify の #body-content に依存しているため VS Code では動かない。載せ替え後に追加する。
for f in json5.min.js wavedrom.min.js wavedrom-skin-default.js chart.umd.js core.js; do
    cp "$root/scripts/$f" "$media/$f"
done
cp "$root/scripts/renderers/wavedrom.js" "$media/renderers/wavedrom.js"
cp "$root/scripts/renderers/chart.js"    "$media/renderers/chart.js"

# sourcemap 参照を剥がす: webview の CSP は default-src \'none\' なので .map の取得が
# ブロックされ、Console に無関係な警告が出続ける。配布物には不要。
find "$media" -name '*.js' -exec sed -i -E '/^\/\/# sourceMappingURL=/d; s@/[*]# sourceMappingURL=[^*]*[*]/@@g' {} +

echo "synced -> $media"
ls -1 "$media" "$media/renderers"
