---
name: ask-copilot
description: >-
  Ask GitHub Copilot CLI for a second AI opinion.
  Use when: "ask-copilot", "copilot", "second opinion", "壁打ち"
metadata:
  author: pokutuna
  version: 0.3.0
  compatibility: GitHub Copilot CLI installed and authenticated
allowed-tools:
  - Bash(copilot *)
  - Read
  - AskUserQuestion
---

# Copilot CLI

GitHub Copilot CLI に質問や依頼を投げ、独立した AI の意見を得る。
コードレビュー、設計相談、調査、質問など用途を問わない。

```bash
copilot --model gpt-5.4 --effort medium \
  --available-tools='view,glob,rg,bash,web_fetch' --allow-all-tools --deny-tool='write' \
  --allow-all-paths \
  --output-format text --no-color --no-ask-user \
  --share=/tmp/copilot-review-latest.md \
  -p "<prompt>"
```

書き込みは `--deny-tool='write'` で禁止したまま、`--allow-all-paths` でファイル読み取りの範囲を CWD 外にも広げる。特定ディレクトリだけ追加したい場合は `--allow-all-paths` の代わりに `--add-dir <path>` を複数指定する。

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

**上記に該当しない場合は必ず AskUserQuestion でユーザーに確認すること。**
特に $ARGUMENTS が空や曖昧な場合、確認なしに copilot を実行してはならない。
確認時は構築したプロンプトの要約・モデル・effort を表示する。

### 3. Run Copilot

```bash
copilot --model <model> --effort <effort> \
  --available-tools='view,glob,rg,bash,web_fetch' --allow-all-tools --deny-tool='write' \
  --allow-all-paths \
  --output-format text --no-color --no-ask-user \
  --share=/tmp/copilot-review-latest.md \
  -p "$(cat <<'PROMPT'
あなたは読み取り専用モードで動作しています。ファイルの読み取り、コード検索、シェルコマンドの実行は可能ですが、ファイルの編集や作成はできません。調査結果の報告のみ行ってください。

<依頼内容をここに記述>
PROMPT
)"
```

`--share` により完了時にセッション全体が `/tmp/copilot-review-latest.md` に markdown で保存される。

Bash ツールの timeout を 300000ms (5分) に設定すること。timeout しても copilot プロセスはバックグラウンドで継続し、完了時にファイルへ書き出される。

### 4. Present results

Bash の timeout 内に完了した場合: 出力をそのまま表示する。

timeout した場合: copilot プロセスを kill してはならない。AskUserQuestion で「Copilot がまだ実行中です。待ちますか?」と確認する。
待つ場合は `/tmp/copilot-review-latest.md` を定期的に Read で読んで完了を待つ。
待たない場合は、後で `/tmp/copilot-review-latest.md` を読めることを伝える。

Copilot の出力を表示する際、冒頭に Copilot CLI による結果である旨を注記。

## Examples

```
/ask-copilot                                    # 会話の文脈からレビュー対象を判断
/ask-copilot staged -y                          # staged changes を確認スキップでレビュー
/ask-copilot この設計方針についてレビューして     # 方針レビュー
/ask-copilot src/auth.ts --model o3             # 特定ファイルをモデル指定でレビュー
/ask-copilot pr エラーハンドリングに注目         # PR 全変更をフォーカス指定でレビュー
```
