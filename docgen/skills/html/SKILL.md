---
name: html
description: HTML ドキュメントを作成・編集する。HTML 形式の説明、調査結果、レポートを求められたときに使う。
metadata:
  author: pokutuna
  compatibility: Claude Code, Codex CLI
---

# HTML ドキュメント

同梱のテンプレートとデザインシステムを使い、独自に見た目を設計しない。

このファイルがあるディレクトリの絶対パスを、シェル変数 `SKILL_DIR` に設定する。Claude Code では
`SKILL_DIR="${CLAUDE_PLUGIN_ROOT}/skills/html"` になる。

## 手順

1. 新規文書では `design-system/` と `template.html` を作業用ディレクトリへコピーし、HTML を
   `{yyyymmdd}-{内容のケバブケース}.html` に改名する。既存文書ではファイル名と同梱済み資産を維持する
2. テンプレートの骨格と `<head>` を保ったまま本文を書く。部品の選び方とマークアップは
   `design-system/component-samples.html` を正とし、使う節だけ読む
3. ライトとダークで描画し、PNG を開いて崩れ・溢れ・重なりを直す。DOM の検査だけで済ませない
   ```sh
   "${SKILL_DIR}/scripts/screenshot.sh" 原稿.html
   "${SKILL_DIR}/scripts/screenshot.sh" 原稿.html --dark
   ```
4. 指定なし、単一ファイル、bundle の場合は、分離状態で編集した原稿を別パスへ bundle する
   ```sh
   "${SKILL_DIR}/scripts/bundle.py" 原稿.html -o 納品先/{name}.html
   ```
   既定は CDN 参照のまま。ネットワークなしなら `--offline --no-webfonts`、Web フォントも埋め込むなら
   `--offline` を使う。複数ファイル構成では分離したまま渡し、複数文書では `design-system/` を共有する
5. bundle した場合は納品物も描画して開く
