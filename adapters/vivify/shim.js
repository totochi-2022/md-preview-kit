/* Vivify アダプタ — ホスト固有の処理をここに閉じ込める
 *
 * core は VS Code の契約（`vscode.markdown.updateContent` イベント）だけを知っている。
 * Vivify は ws で #body-content を差し替えるので、それを検出して同名イベントに翻訳する。
 * 「厳しい方(VS Code)を正とし、緩い方にシムを被せる」— 逆向きにはしない。
 */
(function () {
    'use strict';

    // ---- 更新検出: Vivify の ws UPDATE → VS Code 互換イベント ----
    function installUpdateBridge() {
        var container = document.getElementById('body-content');
        if (!container) return;
        var pending = false;
        new MutationObserver(function () {
            if (pending) return;
            pending = true;
            setTimeout(function () {
                pending = false;
                window.dispatchEvent(new Event('vscode.markdown.updateContent'));
            }, 0);
        }).observe(container, { childList: true, subtree: true });
    }

    // ---- nvim-server(:9998) からの pull 要求に応答するブリッジ ----
    // 親 client は別オリジンなので contentWindow 直読みができず postMessage 経由になる。
    // :PreviewErrors / :PreviewSvg / :PreviewEval がこれを使う。
    //
    // ここには eval がある。core に置いていない理由:
    //   - nvim-server 専用のデバッグ機能で、共通のレンダリング経路ではない
    //   - VS Code では CSP で動かないし、そもそも不要（拡張ホストと直接話せる）
    // 「フェンスの中身を評価する」のとは別物で、評価対象は自分が :PreviewEval で
    // 明示的に送ったコードに限られる。
    function installNvimServerBridge() {
        if (window.__vivGlueBridge) return;
        window.__vivGlueBridge = true;
        window.addEventListener('message', function (ev) {
            var d = ev.data;
            if (!d || d.__nvimServer !== true) return;

            if (d.kind === 'eval') {
                var er = { __vivGlue: true, token: d.token, want: 'eval' };
                try {
                    var v = (0, eval)(d.code);
                    er.result = (typeof v === 'object' && v !== null)
                        ? JSON.stringify(v) : String(v);
                } catch (e) {
                    er.error = String(e);
                }
                try {
                    (ev.source || window.parent).postMessage(er, ev.origin || '*');
                } catch (_) { /* 送れなくても致命ではない */ }
                return;
            }

            if (d.kind !== 'collect') return;
            var reply = { __vivGlue: true, token: d.token, want: d.want };
            if (d.want === 'svg') {
                // 描画に成功した SVG。chart は canvas(ビットマップ)なのでここには載らない。
                reply.svgs = [].slice.call(
                    document.querySelectorAll('.viv-wavedrom svg, .viv-ladder svg')
                ).map(function (el, i) { return { index: i, svg: el.outerHTML }; });
            } else {
                reply.errors = [].slice.call(
                    document.querySelectorAll('.viv-render-error')
                ).map(function (el, i) {
                    return {
                        index: i,
                        kind: el.dataset.vivKind || '',
                        message: el.dataset.vivMessage || el.textContent
                    };
                });
            }
            try {
                (ev.source || window.parent).postMessage(reply, ev.origin || '*');
            } catch (_) { /* 送れなくても致命ではない */ }
        });
    }

    function init() {
        installUpdateBridge();
        installNvimServerBridge();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
