---
name: html
description: HTML ドキュメントの作成・編集。HTML 形式の説明、調査結果、レポートを求められたときに使う。
compatibility: Requires python3 for bundle.py
---

# HTML ドキュメント

同梱のテンプレートとデザインシステムで HTML ドキュメントを作る。見た目はデザインシステムが決めるので、
書き手は骨格に本文を入れ、部品のクラスを当てる。

## 手順

1. `${CLAUDE_PLUGIN_ROOT}/skills/html/assets/` の `design-system/` と `template.html` を作業ディレクトリへコピーし、
   HTML を `{yyyymmdd}-{内容のケバブケース}.html` に改名する。`design-system/` が既にあればそれを使う。
   既存文書はファイル名と資産を変えずに編集する
2. テンプレートの骨格と `<head>` を保って本文を書く。部品とマークアップは `references/component-samples.html` を正とする。
   ページ固有の `<style>` は図の配置調整など最小限にし、色はトークンの変数で指定する
3. 分離した構成を求められた場合を除き、単一ファイルに bundle して渡す。ユーザーがオフラインで開ける形を
   求めたときだけ `--offline` (Web フォントを省くなら `--offline --no-webfonts`) を付ける
   ```sh
   "${CLAUDE_PLUGIN_ROOT}/skills/html/scripts/bundle.py" <input.html> -o <output.html>
   ```
