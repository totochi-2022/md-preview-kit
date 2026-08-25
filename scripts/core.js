/* md-preview-kit core — レンダラ登録と描画ディスパッチ
 *
 * フェンス言語ごとのレンダラを登録し、`pre.language-<lang>` を走査して描画する。
 * ここには環境固有の処理を一切置かない（ホストとの通信・更新検出はアダプタの責務）。
 *
 * 契約:
 *   MdPreviewKit.register(lang, render)
 *     render(pre, source) — pre を描画結果の要素で置き換える。throw すればエラー表示。
 *   MdPreviewKit.parse(text)   JSON5 パース（eval を使わない。理由は下記）
 *   MdPreviewKit.refresh()     再走査を予約する（アダプタが更新を検出したら呼ぶ）
 *
 * 再描画の契約は VS Code に合わせてある。VS Code 1.63 以降プレビューは差分 DOM 更新
 * になり、スクリプトは初回1度だけ初期化され `vscode.markdown.updateContent` を自分で
 * 拾う設計。core はこのイベントを直接聞くので、他ホストのアダプタは同名イベントを
 * dispatch すればよい（Vivify 側は adapters/vivify/shim.js が行う）。
 */
(function (global) {
    'use strict';

    var registry = [];
    var scheduled = false;

    // ★ eval を使わないこと自体が要件:
    //   1. VS Code のプレビュー webview は CSP が script-src 'nonce-...' で unsafe-eval が
    //      無く、new Function / eval は動かない。拡張として配る以上ここが下限になる。
    //   2. フェンスの中身を評価する実装は任意コード実行になる。同種の実装で実際に
    //      脆弱性報告が出ている(markdown-preview-enhanced #2315: WaveDrom eval 経由の
    //      任意ファイル書き込み)。他人に md を配って開かせる用途では許容できない。
    //
    // 制約: 関数を含む設定(Chart の callback 等)は書けない。CSP 下では原理的に不可能
    // なので、実装上の都合ではなく仕様。
    function parse(text) {
        if (typeof JSON5 === 'undefined') {
            throw new Error('JSON5 が読み込まれていない (scripts の順序を確認)');
        }
        return JSON5.parse(text);
    }

    // フェンスは <pre class="language-wavedrom"><code>… で来る。
    // (Vivify は highlight.ts パッチ、VS Code の markdown-it は既定でこの形)
    function fenceText(pre) {
        var code = pre.querySelector('code');
        return code ? code.textContent : pre.textContent;
    }

    function showError(pre, kind, e) {
        var msg = (e && e.message) ? e.message : String(e);
        var p = document.createElement('pre');
        p.style.color = '#e06c75';
        p.style.whiteSpace = 'pre-wrap';
        p.textContent = kind + ' render error: ' + msg;
        // 収集用の目印。アダプタがここを走査してホストへ返す
        // (nvim-server の :PreviewErrors 等)。
        p.className = 'viv-render-error';
        p.dataset.vivKind = kind;
        p.dataset.vivMessage = msg;
        pre.replaceWith(p);
    }

    function processAll(root) {
        root = root || document;
        for (var i = 0; i < registry.length; i++) {
            var entry = registry[i];
            var list = root.querySelectorAll('pre.language-' + entry.lang);
            for (var j = 0; j < list.length; j++) {
                var pre = list[j];
                try {
                    entry.render(pre, fenceText(pre));
                } catch (e) {
                    showError(pre, entry.lang, e);
                }
            }
        }
    }

    // 走査は次tickにまとめる。理由が2つある:
    //  - core.js の直後に読まれるレンダラが register し終える前に初回走査が走らないように
    //  - 自分の DOM 変更が更新検出を再入させても1回に畳むため
    // 描画済みフェンスは class ごと置換されるので、多重に走っても二重描画にならない。
    function refresh() {
        if (scheduled) return;
        scheduled = true;
        setTimeout(function () {
            scheduled = false;
            processAll(document);
        }, 0);
    }

    global.MdPreviewKit = {
        register: function (lang, render) {
            registry.push({ lang: lang, render: render });
            refresh();
        },
        parse: parse,
        fenceText: fenceText,
        error: showError,
        refresh: refresh
    };

    // VS Code の更新イベント（他ホストのアダプタも同名を dispatch する）
    global.addEventListener('vscode.markdown.updateContent', refresh);

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', refresh);
    } else {
        refresh();
    }
})(window);
