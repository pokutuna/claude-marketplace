/* docgen - Mermaid レンダリングと原文コピー
 * mermaid 本体より後に読み込む。
 * 対象は <pre class="dg-mermaid">...</pre>。描画後は div.dg-mermaid に置き換わる。
 * 原文を保持し、テーマ切り替え時に描き直す。
 */
(function () {
  if (!window.mermaid) return;

  var blocks = [];

  function isDark() {
    var t = document.documentElement.getAttribute('data-theme');
    if (t) return t === 'dark';
    return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
  }

  function config() {
    var css = getComputedStyle(document.documentElement);
    var v = function (n) { return css.getPropertyValue(n).trim(); };
    var surface = v('--dg-surface'), alt = v('--dg-surface-alt');
    var ink = v('--dg-ink-body'), border = v('--dg-border');
    return {
      startOnLoad: false,
      securityLevel: 'strict',
      theme: 'base',
      darkMode: isDark(),
      fontFamily: v('--dg-font-sans'),
      flowchart: { htmlLabels: true, padding: 12 },
      sequence: { mirrorActors: false, messageMargin: 40, boxMargin: 10 },
      themeVariables: {
        background: surface,
        primaryColor: surface,
        primaryTextColor: ink,
        primaryBorderColor: border,
        secondaryColor: alt,
        secondaryTextColor: ink,
        secondaryBorderColor: border,
        tertiaryColor: alt,
        tertiaryTextColor: ink,
        tertiaryBorderColor: border,
        lineColor: border,
        arrowheadColor: border,
        textColor: ink,
        noteBkgColor: alt,
        noteTextColor: ink,
        noteBorderColor: border,
        actorBkg: surface,
        actorBorder: border,
        actorTextColor: ink,
        signalColor: ink,
        signalTextColor: ink,
        labelBoxBkgColor: alt,
        labelBoxBorderColor: border,
        labelTextColor: ink,
        loopTextColor: ink,
        activationBkgColor: alt,
        activationBorderColor: border,
        sequenceNumberColor: surface,
        mainBkg: surface,
        nodeBorder: border,
        clusterBkg: alt,
        clusterBorder: border,
        edgeLabelBackground: surface,
        titleColor: ink
      }
    };
  }

  function collect() {
    document.querySelectorAll('pre.dg-mermaid').forEach(function (pre, i) {
      var code = pre.querySelector('code') || pre;
      var src = code.textContent.replace(/^\n+|\s+$/g, '');
      var host = document.createElement('div');
      host.className = 'dg-mermaid';
      pre.parentNode.replaceChild(host, pre);
      blocks.push({ host: host, src: src, id: 'dg-mermaid-' + i });
    });
  }

  function render() {
    if (!blocks.length) return;
    mermaid.initialize(config());
    blocks.forEach(function (b) {
      mermaid.render(b.id, b.src).then(function (res) {
        b.host.innerHTML = res.svg;
        if (window.dgCopy) {
          b.host.appendChild(window.dgCopy.button(b.src, 'Mermaid 記法をコピー'));
        }
      }).catch(function (err) {
        var pre = document.createElement('pre');
        pre.textContent = b.src;
        b.host.innerHTML = '';
        b.host.appendChild(pre);
        if (window.console) console.error('mermaid render failed', err);
      });
    });
  }

  function start() {
    collect();
    // Web フォント確定前に測ると文字が箱から溢れるので、フォントを待つ
    var ready = (document.fonts && document.fonts.ready) || Promise.resolve();
    ready.then(render, render);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }

  document.addEventListener('dg:themechange', render);
})();
