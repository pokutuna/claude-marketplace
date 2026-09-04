# docgen

テキストベースの成果物を作る Claude Code プラグイン。日本語の文章規範と HTML ドキュメントの
デザインシステムを提供する。

見た目の判断はデザインシステム側が済ませていて、書き手は `dg-` クラスを当てるだけで
一貫した文書になる。成果物は既定で単一の HTML ファイル。

## Skills

| Skill | Description |
|-------|-------------|
| `html` | HTML ドキュメントを作成・編集する (既定は単一ファイルに bundle) |
| `writing` | 日本語の説明文や技術文書を明確で自然な文章として作成・推敲する |

## デザインシステム

`skills/html/assets/design-system/` にある。部品と書き方は `skills/html/references/component-samples.html` を正とする。
設計意図と運用ルールは `skills/html/references/DESIGN_SYSTEM.md` にまとめてある。
書き始めは `skills/html/assets/template.html` をコピーする (`<head>` の読み込み順と骨格が入っている)。

- 用語集 `aside` の有無で 2 カラム / 1 カラムを自動切替
- ダークモード: OS 設定に追従し、右上のボタンで上書き。選択は localStorage に保存され、
  描画前に確定するのでちらつかない
- 有彩色は teal (リンク) と amber (強調) の 2 色。差分の緑赤は `pre.dg-diff` 専用
- 数式は MathJax の SVG 出力。hover の copy ボタンでデリミタ込みの LaTeX を取り出せる
- Mermaid はテーマに合わせて描画し、原文を copy できる。テーマ切替で描き直す
- 表は列幅固定で溢れない。列が多い表だけ `.dg-table-scroll` で包んで箱内スクロール
- インライン SVG の線は `currentColor` でテーマに追随
- `h2` / `h3` に hover で現れるアンカーリンク。`id` が無い見出しには文面から付く

## Scripts

| Script | 用途 |
|--------|------|
| `scripts/bundle.py` | HTML と `design-system/` を 1 ファイルにまとめる。標準ライブラリのみ。`--offline` では埋め込んだライブラリの名前・版・ライセンスをフッターと HTML コメントに記す |
| `scripts/screenshot.sh` | headless Chrome でライト / ダークの PNG を撮る。デザインシステムを変更したときに見本ページを目視確認する用途で、文書を書くたびには使わない |

```
bundle.py <input.html> -o <output.html>                        # CDN 参照のまま、数十 KB
bundle.py <input.html> -o <output.html> --offline --no-webfonts  # ネットワーク不要、約 6 MB
bundle.py <input.html> -o <output.html> --offline                # Web フォントも埋め込み、約 27 MB
screenshot.sh <input.html> [--dark] [--no-network] [--width N] [--height N] [-o <output.png>]
```

## Installation

```
/plugin install docgen@pokutuna-plugins
```
