/* Vivify custom glue
 * ```wavedrom / ```chart フェンスを描画する。
 * config.json "scripts" で wavedrom(min)+skin+chart の後に読み込まれ、ページ末尾に
 * インライン展開される。初期描画に加え、ws UPDATE で #body-content が差し替わるのを
 * MutationObserver で拾って再描画する。 */
(function () {
    'use strict';
    var wdIndex = 0;

    // WaveJSON / Chart config は JS オブジェクトリテラル(キー無引用符可)。
    // ローカルプレビュー専用なので WaveDrom 本家同様 Function 評価で読む。
    function parseObj(text) {
        return new Function('return (' + text + ');')();
    }

    function showError(pre, kind, e) {
        var p = document.createElement('pre');
        p.style.color = '#e06c75';
        p.style.whiteSpace = 'pre-wrap';
        p.textContent = kind + ' render error: ' + (e && e.message ? e.message : e);
        pre.replaceWith(p);
    }

    // フェンスは highlight.ts パッチにより <pre class="language-wavedrom"><code>...
    // として出力される。pre の textContent が元ソース。
    function fenceText(pre) {
        var code = pre.querySelector('code');
        return code ? code.textContent : pre.textContent;
    }

    function renderWavedrom(pre) {
        try {
            var src = parseObj(fenceText(pre));
            var idx = wdIndex++;
            var div = document.createElement('div');
            div.id = 'WaveDrom_Display_' + idx;
            div.className = 'viv-wavedrom';
            pre.replaceWith(div);
            WaveDrom.RenderWaveForm(idx, src, 'WaveDrom_Display_');
        } catch (e) {
            showError(pre, 'wavedrom', e);
        }
    }

    function renderChart(pre) {
        try {
            var cfg = parseObj(fenceText(pre));
            // 自動縮小(responsive フィードバックループ)防止:
            // 固定高の position:relative コンテナ + maintainAspectRatio:false で
            // canvas がコンテナを埋める形にし、高さの再帰参照を断つ。
            cfg.options = cfg.options || {};
            if (cfg.options.responsive === undefined) cfg.options.responsive = true;
            if (cfg.options.maintainAspectRatio === undefined) cfg.options.maintainAspectRatio = false;
            var wrap = document.createElement('div');
            wrap.className = 'viv-chart';
            wrap.style.position = 'relative';
            wrap.style.maxWidth = '48rem';
            wrap.style.height = '24rem';
            var canvas = document.createElement('canvas');
            wrap.appendChild(canvas);
            pre.replaceWith(wrap);
            new Chart(canvas, cfg);
        } catch (e) {
            showError(pre, 'chart', e);
        }
    }

    function processAll(root) {
        root = root || document;
        root.querySelectorAll('pre.language-wavedrom').forEach(renderWavedrom);
        root.querySelectorAll('pre.language-chart').forEach(renderChart);
    }

    function run() {
        processAll(document);
        var container = document.getElementById('body-content');
        if (!container) return;
        // ws UPDATE で innerHTML が差し替わる。自分の DOM 変更での再入を避けるため
        // 次tickにまとめて再スキャン。処理済みは code.language-* が消えるので二重描画しない。
        var pending = false;
        new MutationObserver(function () {
            if (pending) return;
            pending = true;
            setTimeout(function () { pending = false; processAll(container); }, 0);
        }).observe(container, { childList: true, subtree: true });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', run);
    } else {
        run();
    }
})();
