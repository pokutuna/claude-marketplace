# デザインシステム

`document.css` と付属の JS が持つ規則をまとめた開発者向けの資料。書き手 (エージェント) 向けの
指示は `../SKILL.md` と `component-samples.html` にあり、こちらはその土台を変更する人が読む。

## 構成

| ファイル | 役割 |
| --- | --- |
| `document.css` | トークンと全部品のスタイル。単独で完結する |
| `theme.js` | `data-theme` の確定と切り替えボタンの生成。描画前に走らせる |
| `copy.js` | copy ボタンの生成。`pre` を `div.dg-code` で包む |
| `anchor.js` | `main` 内の h2 / h3 にアンカーリンクと id を付ける |
| `math.js` | MathJax の設定と数式の copy ボタン |
| `mermaid.js` | Mermaid のテーマ設定、再描画、原文の copy ボタン |
| `component-samples.html` | 全部品の見本。マークアップの正 |

## トークン

色と寸法はすべて `:root` の CSS 変数で、ダークは `:root[data-theme="dark"]` と
`@media (prefers-color-scheme: dark)` の両方に同じ値を書く。片方だけ変えない。

### 面と文字

| トークン | 用途 |
| --- | --- |
| `--dg-bg` | ページの背景 |
| `--dg-surface` | 部品の面。カード、note、引用、コード、図、表の行見出し |
| `--dg-surface-alt` | 一段沈んだ面。目次、インラインコード、表の列見出し |
| `--dg-ink` | 見出しと `strong` の文字 |
| `--dg-ink-body` | 本文の文字 |
| `--dg-muted` | 補助の文字。ヘッダー、フッター、キャプション、箇条書きのマーカー |
| `--dg-border` | 部品の外枠、表の外枠、列見出しの下線 |
| `--dg-rule` | 細い区切り線。h1 の下線、表の内側、用語集の区切り、`hr` |

ダークでは背景と面のコントラストを 1.15:1 まで落とすとブロックが沈む。現在の値
(`#1A1D22` / `#232830` / `#4A5262`) はその段差を確保したもの。

### 有彩色

| トークン | 用途 |
| --- | --- |
| `--dg-link` | teal。リンク、h1、目次番号、note のラベル、steps の番号、コードの予約語、選択範囲 |
| `--dg-accent` | amber。`em`、コードの文字列と数値 |
| `--dg-add-bg` / `--dg-add-ink` | 差分の追加行。`pre.dg-diff` 専用 |
| `--dg-del-bg` / `--dg-del-ink` | 差分の削除行。`pre.dg-diff` 専用 |
| `--dg-c1` 〜 `--dg-c5` | 系列色。`figure svg` と `.dg-chip` の中でだけ効く |

teal `#008080` は暗背景で 3.79:1 しかなく AA を満たさないため、ダークは `#2DD4BF` に切り替える。
アクセントに orange `#C2410C` を選ぶと色相 17° が diff の削除色と衝突するので、amber 系 (26°) を使う。
系列色は pokutuna.com のパレットを基に Okabe-Ito 系で揃えてある。

### 寸法

| トークン | 用途 |
| --- | --- |
| `--dg-font-sans` | 本文の書体 (Ubuntu Sans + Noto Sans JP) |
| `--dg-font-mono` | コード、ヘッダー、番号の書体 (Ubuntu Mono) |
| `--dg-radius` | 部品の角丸 |
| `--dg-border-w` | 枠線と罫線の太さ |
| `--dg-measure` | 用語集なしのときのページ幅 |

## ブロック

強調 (`.dg-note`) と補助情報 (`.dg-sub`) の 2 種類を持つ。色では区別せず、面と枠で区別する。

- `.dg-note` は白地に枠。`data-label` があると枠にまたがる teal のタグが `::before` で付く。
  タグの分だけ上に余白が要るので、`[data-label]` のときだけ `margin-top` と `padding-top` を増やす
- `.dg-sub` は `--dg-surface-alt` の面で枠を持たない。ラベルは本文と同じ大きさの teal 太字
- `nav.dg-toc` は `.dg-sub` と同じ体裁で、「目次」のラベルを CSS で付ける。目次専用の装飾は持たない

## レイアウト

- `.dg-wrap:has(> aside)` で 2 カラム (本文 + 300px)、`aside` がなければ `.dg-page` 全体を
  `--dg-measure` まで狭める。切り替えのクラスは持たない
- `.dg-wide` は本文ではなく画面を基準に中央寄せする。幅は `min(100vw - 64px, 1600px)`。
  margin-left は main の左端の画面座標から逆算する。1000px 以下では無効
- `.dg-table-scroll` や `figure` の margin 指定が後勝ちで margin-left を打ち消すので、
  `.dg-page .dg-wide` で特異性を上げてある

## 注意点

- `pre.dg-diff` の中は `code` を `white-space: normal` にして、span 間の改行を折りたたむ。
  これがないと span を改行で区切って書いたときに 1 行おきに空行が入る
- 部品を追加したら `component-samples.html` にも実例を置く。見本にない部品は動作が確認されない
- 変更後は `scripts/screenshot.sh` でライトとダークを描画して目視する。DOM 検査では
  レイアウトの崩れも色の不在も捕まえられない
