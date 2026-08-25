/* ```chart フェンス → グラフ (Chart.js) */
(function () {
    'use strict';
    var K = window.MdPreviewKit;

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
    });
})();
