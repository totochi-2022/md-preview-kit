/* ```wavedrom フェンス → タイミング図 (WaveDrom) */
(function () {
    'use strict';
    var K = window.MdPreviewKit;
    var index = 0;

    K.register('wavedrom', function (pre, source) {
        var obj = K.parse(source);
        var i = index++;
        var div = document.createElement('div');
        div.id = 'WaveDrom_Display_' + i;
        div.className = 'viv-wavedrom';
        pre.replaceWith(div);
        // ★ 必ず RenderWaveForm（パース済みオブジェクトを渡す形）を使うこと。
        // WaveDrom には DOM の textarea を eval して読む別経路があり、そちらは
        // CSP(unsafe-eval 無し)下で落ちる。この呼び方ならその経路を踏まない。
        WaveDrom.RenderWaveForm(i, obj, 'WaveDrom_Display_');
    });
})();
