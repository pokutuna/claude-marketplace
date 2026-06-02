---
name: ask-copilot
description: Ask GitHub Copilot CLI for a second AI opinion. "ask copilot", "copilot と相談" などで起動。
argument-hint: "[target] [focus] [--model NAME] [--effort LEVEL] [-y]"
metadata:
  author: pokutuna
  compatibility: GitHub Copilot CLI installed and authenticated
allowed-tools:
  - Bash(copilot *)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/share-path.sh)
  - Read
  - AskUserQuestion
---

# Copilot CLI

GitHub Copilot CLI に質問や依頼を投げ、独立した AI の意見を得る。
コードレビュー、設計相談、調査、質問など用途を問わない。

このセッションの `--share` 保存先 (skill 起動時に確定):

SHARE_FILE = !`bash ${CLAUDE_SKILL_DIR}/scripts/share-path.sh`

以降の手順では上記パスを `--share` に指定し、ユーザーへの案内にも使う。

```bash
copilot --model gpt-5.4 --effort medium \
  --available-tools='view,glob,rg,bash,web_fetch' --allow-all-tools --deny-tool='write' \
  --allow-all-paths \
  --output-format text --no-color --no-ask-user --silent \
  --share="<上記 SHARE_FILE>" \
  -p "<prompt>"
```

書き込みは `--deny-tool='write'` で禁止したまま、`--allow-all-paths` でファイル読み取りの範囲を CWD 外にも広げる。特定ディレクトリだけ追加したい場合は `--allow-all-paths` の代わりに `--add-dir <path>` を複数指定する。

`--share` の保存先は `$TMPDIR` (macOS では `/var/folders/.../T/`、未設定なら `/tmp`) 配下にタイムスタンプ付きファイル名で生成する。OS のクリーンアップ (macOS は 3 日アクセスなしで削除) までは残るため、後から参照可能。

<ARGUMENTS>
$ARGUMENTS
</ARGUMENTS>

## Arguments

- **レビュー内容**: $ARGUMENTS と会話コンテキストからレビュー対象と観点を判断する
- **オプション**: `--model <model>` (デフォルト: gpt-5.4), `--effort <level>` (デフォルト: medium), `-y`/`--yes` で確認スキップ

## Instructions

### 1. Build prompt

会話コンテキストと $ARGUMENTS から、Copilot に渡すプロンプトを日本語で構築する。
Copilot が自律的にファイルを読んだり git コマンドを実行できるため、Claude が情報を集める必要はない。
「何を聞きたいか」「どの観点で見てほしいか」を明確に指示するプロンプトを作る。

ユースケースとプロンプトに含めるべき観点の例:
- コードレビュー: 対象範囲、注目すべき観点 (パフォーマンス、セキュリティ、可読性など)
- 設計相談: 現状の設計、検討中の選択肢、トレードオフの判断基準
- 調査: 調べたいこと、背景、期待するアウトプットの粒度
- 質問: 具体的な疑問点、自分の理解や仮説
- セカンドオピニオン: 自分のアプローチ、懸念点、別案があるか

### 2. Confirm with user

以下の場合は確認をスキップして Step 3 に進んでよい:
- `-y`/`--yes` が指定されている
- $ARGUMENTS でレビュー対象と観点が明確に指定されている (例: `staged`, `src/auth.ts`, `pr エラーハンドリングに注目`)

**上記に該当しない場合は必ず AskUserQuestion ツールでユーザーに確認すること。**
テキストで「〜で進めていいですか？」と聞くのは禁止。必ず AskUserQuestion を呼び出す。
特に $ARGUMENTS が空や曖昧な場合、確認なしに copilot を実行してはならない。

AskUserQuestion の使い方:

**ケース A — プロンプトを構築できる場合 (対象と観点が推定できる)**
- 質問文には構築したプロンプトの要約 (対象・背景・聞きたいこと) を短くまとめて含める
- 選択肢: 「このまま実行」「プロンプトを修正」「中止」

**ケース B — プロンプトを構築できない場合 ($ARGUMENTS 空かつ会話文脈から対象/観点が読み取れない)**
- まず「何を聞きたいか」を引き出す AskUserQuestion を先に呼ぶ (対象のファイル/PR/staged/設計相談などの選択肢、または自由記述)
- 回答を受け取ってからプロンプトを構築し、改めてケース A の確認 AskUserQuestion を呼ぶ (二段階)

共通ルール:
- プロンプトの詳細な要旨や内容は、AskUserQuestion の `question` や選択肢の `description` に入れる。ツール外のテキストに長文の要約を出力しない
- モデル・effort は **質問文・選択肢のラベル・description のいずれにも一切含めない** (「モデル」「effort」「gpt-5.4」「medium」などの語も登場させない)。デフォルトの gpt-5.4 / medium を使い、$ARGUMENTS で明示指定された場合のみ従う

### 3. Run Copilot

冒頭で確定した `SHARE_FILE` のパスをそのまま `--share` に文字列で指定する (Bash 呼び出しの中で `$TMPDIR` を再展開しない)。

```bash
copilot --model <model> --effort <effort> \
  --available-tools='view,glob,rg,bash,web_fetch' --allow-all-tools --deny-tool='write' \
  --allow-all-paths \
  --output-format text --no-color --no-ask-user --silent \
  --share="<冒頭で確定した SHARE_FILE>" \
  -p "$(cat <<'PROMPT'
あなたは読み取り専用モードで動作しています。ファイルの読み取り、コード検索、シェルコマンドの実行は可能ですが、ファイルの編集や作成はできません。調査結果の報告のみ行ってください。

<依頼内容をここに記述>
PROMPT
)"
```

`--share` により完了時にセッション全体 (思考・ツール実行ログ・最終回答) が SHARE_FILE に markdown で保存される。後で参照できるよう、生成したパスを必ずユーザーに伝える。

Bash ツールの timeout を 300000ms (5分) に設定すること。timeout しても copilot プロセスはバックグラウンドで継続し、完了時にファイルへ書き出される。

### 4. Present results

Bash の timeout 内に完了した場合: stdout をそのまま表示する。冒頭に Copilot CLI による結果である旨を注記、末尾に保存先パス (SHARE_FILE の値) を明示する。

思考過程やツール実行の詳細が必要になった場合は、SHARE_FILE を Read で読む (全文が残っている)。

timeout した場合: copilot プロセスを kill してはならない。AskUserQuestion で「Copilot がまだ実行中です。待ちますか?」と確認する。
待つ場合は SHARE_FILE を定期的に Read で読んで完了を待つ。完了後は最後の `### 💬 Copilot` セクション (最終回答) を読めばよい。
待たない場合は、後で SHARE_FILE を読めることをパスとともに伝える。

## Examples

```
/ask-copilot                                    # 会話の文脈からレビュー対象を判断
/ask-copilot staged -y                          # staged changes を確認スキップでレビュー
/ask-copilot この設計方針についてレビューして     # 方針レビュー
/ask-copilot src/auth.ts --model o3             # 特定ファイルをモデル指定でレビュー
/ask-copilot pr エラーハンドリングに注目         # PR 全変更をフォーカス指定でレビュー
```
