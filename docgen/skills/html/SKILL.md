---
name: html
description: 概念・仕組み・調査結果・レポートを、単一ファイルの HTML ドキュメントとして作成・編集する。「HTML で」「HTML レポート」「ドキュメントにまとめて」「html にして」などで起動。デザインシステム (ダークモード、用語集、数式、Mermaid) を同梱する。
metadata:
  author: pokutuna
  compatibility: Claude Code, Codex CLI
---

# HTML ドキュメント

見た目の判断はデザインシステムが済ませている。書き手がやるのは、マークアップと `dg-` クラスを
当てることだけ。内容の質 (説明の順序、用語定義、粒度) は別スキルの領分で、ここでは扱わない。

## 手順

1. 作業ディレクトリに `${CLAUDE_PLUGIN_ROOT}/skills/html/design-system/` をコピーし、
   `${CLAUDE_PLUGIN_ROOT}/skills/html/template.html` を `{yyyymmdd}-{内容のケバブケース}.html` として
   隣に置いて書き始める。`<head>` の読み込みと骨格が入っている。既存文書の更新では名前を変えない
2. 描画して目で確認する。DOM の検査は検証にならない
   ```
   ${CLAUDE_PLUGIN_ROOT}/skills/html/scripts/screenshot.sh 原稿.html          # ライト
   ${CLAUDE_PLUGIN_ROOT}/skills/html/scripts/screenshot.sh 原稿.html --dark   # ダーク
   ```
   PNG を Read で開き、崩れ・溢れ・重なりを直す。用語集・表・図・数式は必ず見る
3. 単一ファイルにまとめて納品する。指定がなければ保存先は現在の作業ディレクトリ
   ```
   ${CLAUDE_PLUGIN_ROOT}/skills/html/scripts/bundle.py 原稿.html -o 納品先/{name}.html
   ```
   - 既定は CDN 参照のまま (数十 KB)。ネットワークのない環境向けには `--offline` (約 6 MB)
   - `--offline` に `--no-webfonts` を足すとシステムフォントに落ちる。省くと Noto Sans JP が
     埋め込まれて 27 MB になる
   - 分離した状態 (HTML + `design-system/`) を渡すのは、複数文書で CSS を共有するときと、
     デザインシステム自体を求められたときだけ

## マークアップ

部品と書き方は `design-system/component-samples.html` を正とする。書く前に読む。
CSS 冒頭のコメントに部品の一覧がある。

骨格は次のとおり (`template.html` と同じ)。`<head>` の読み込み順は template から変えない。

```html
<div class="dg-page">
  <header class="dg-header"><span>分類</span><span>日付・版・実験番号など</span></header>
  <h1>題名</h1>
  <p class="dg-lede">リード文</p>
  <nav class="dg-toc"><ol><li><a href="#s1">節</a></li></ol></nav>
  <div class="dg-wrap">
    <main> <h2 id="s1">節</h2> ... </main>
    <aside> <h2>用語</h2> <dl><dt>用語</dt><dd>定義</dd></dl> </aside>  <!-- 任意 -->
  </div>
  <footer class="dg-footer">出所・日付</footer>
</div>
```

- `aside` があれば 2 カラム、なければ 1 カラム。切り替えのクラスは無い
- `h2` / `h3` には hover で `#` のアンカーリンクが付く。目次から参照する `h2` には `id` を書く。
  書かなければ文面から生成される
- 専門用語は本文で使う前に定義し、`aside` の用語集にも載せる
- 素の要素にそのまま効く: `p` `a` `strong` `em` `ul` `ol` `blockquote` `table` `figure` `pre`
- クラスが要るのは: `.dg-note` (強調)、`.dg-sub` (補助情報)、`.dg-card` + `.dg-grid`、
  `.dg-chip`、`ol.dg-steps`、`p.dg-translation` (引用の訳文)、`.dg-table-scroll`、`.dg-wide`、
  `pre.dg-diff`、`pre.dg-mermaid`
- ブロックは 2 種類。読み飛ばしてほしくない内容は `.dg-note`、本題から外れる前提や参考情報は
  `.dg-sub`。どちらも `data-label` の語で種別を示し、色は変えない。ラベルは省ける
- 表は `thead th` が列見出し、`tbody th` が行見出し。列幅は固定なので溢れない。列が多くて
  読めない表だけ `.dg-table-scroll` で包む
- 幅は本文幅か画面幅の 2 択。横長の表・図・画像・コード、図を横に並べる `.dg-grid` には `.dg-wide`
  を足すと画面幅いっぱいに広がる
- ページ固有の `<style>` は図の寸法調整など最小限にとどめる。色を直接書かない

## 色と強調

有彩色は teal (リンク・キーワード) と amber (`em` による強調) の 2 色だけ。差分の緑赤は
`pre.dg-diff` 専用の機能色で、本文には使わない。`em` は節ごとに 1 箇所を目安にする。
色はすべて CSS 変数で、ダークモードは自動で追随する。図やページ固有の `<style>` で色を
指定するときに使う変数は、見本の「色のトークン」節にある。

## 図

- 自作図はインライン SVG。`figure` の直下に置き、線と文字に色を書かない (`currentColor` で
  テーマに追随する)。塗りは `class="fill"`、色変えは `class="link"` / `class="accent"`
- 系列を色で区別するときだけ `c1`〜`c5` を順に付ける (`.dg-chip` にも可)。本文には使わない
- フローチャート・シーケンス図・状態遷移図は `pre.dg-mermaid` に Mermaid 記法で書く。
  描画後も hover の copy ボタンで原文を取り出せる
- アスキーアート、絵文字、矢印文字を図記号に使わない
- 一方向の単純な手順は図にせず `ol.dg-steps` で書く

## コード・数式

- `pre > code.language-*` に書く。色を付けないなら `language-plaintext`。copy ボタンは自動で付く
- 差分は `pre.dg-diff` の各行を `span.add` / `span.del` / `span.ctx` で包む。行頭記号は書かない
- 数式はインライン `$...$`、ディスプレイ `$$...$$`。ベクトル・行列は `\boldsymbol{}`、
  スカラーは装飾しない。copy ボタンでデリミタ込みの LaTeX が取れる
- `window.MathJax` をページ側で再定義しない

## Examples

- 「Count-Min Sketch の仕組みを HTML で説明して」
  → design-system をコピー、`20260902-count-min-sketch.html` を書き、screenshot.sh で両テーマを
  確認、bundle.py で単一ファイルにして渡す
- 「この調査結果を HTML レポートにして、オフラインでも見られるように」
  → 同じ手順で `bundle.py --offline --no-webfonts`
- 「3 本のレポートで CSS を共有したい」
  → バンドルせず `design-system/` を 1 つ置き、各 HTML から相対パスで参照する
