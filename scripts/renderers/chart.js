/* ```chart フェンス → グラフ (Chart.js) */
(function () {
    'use strict';

    function setup(K) {
        K.register('chart', function (pre, source) {
            var cfg = K.parse(source);
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
        }, { needs: ['JSON5', 'Chart'] });
    }

    // core が先に読まれている保証は無い(VS Code の previewScripts は非同期・順不同)。
    if (window.MdPreviewKit) setup(window.MdPreviewKit);
    else (window.__MdPreviewKitQueue = window.__MdPreviewKitQueue || []).push(setup);
})();
