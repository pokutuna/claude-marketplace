---
name: review-copilot-cli
description: >-
  Ask GitHub Copilot CLI to review code, design, or approach. Provides a second AI opinion.
  Use when: "copilot review", "review-copilot-cli", "copilot にレビュー", "second opinion", "セカンドオピニオン"
metadata:
  author: pokutuna
  version: 0.1.0
  compatibility: GitHub Copilot CLI installed and authenticated
allowed-tools:
  - Bash(copilot *)
  - Read
  - AskUserQuestion
---

# Copilot CLI Review

GitHub Copilot CLI にレビューを依頼し、独立した AI の意見を得る。
コードレビュー、設計方針、アーキテクチャ、アプローチなど何でもレビューできる。

```bash
copilot --model gpt-5.4 --effort high \
  --available-tools='view,glob,rg,bash,web_fetch' --allow-all-tools --deny-tool='write' \
  --output-format text --no-color --no-ask-user \
  --share=/tmp/copilot-review-latest.md \
  -p "<prompt>"
```

<ARGUMENTS>
$ARGUMENTS
</ARGUMENTS>

## Arguments

- **レビュー内容**: $ARGUMENTS と会話コンテキストからレビュー対象と観点を判断する
- **オプション**: `--model <model>` (デフォルト: gpt-5.4), `--effort <level>` (デフォルト: high), `-y`/`--yes` で確認スキップ

## Instructions

### 1. Build review prompt

会話コンテキストと $ARGUMENTS から、Copilot に渡すレビュープロンプトを日本語で構築する。
Copilot が自律的にファイルを読んだり git コマンドを実行できるため、Claude が情報を集める必要はない。
「何をレビューしてほしいか」「どの観点で見てほしいか」を明確に指示するプロンプトを作る。

### 2. Confirm with user

`-y`/`--yes` 指定時はスキップ。
それ以外は AskUserQuestion で構築したプロンプト・モデル・effort を表示して確認。

### 3. Run Copilot

```bash
copilot --model <model> --effort <effort> \
  --available-tools='view,glob,rg,bash,web_fetch' --allow-all-tools --deny-tool='write' \
  --output-format text --no-color --no-ask-user \
  --share=/tmp/copilot-review-latest.md \
  -p "$(cat <<'PROMPT'
あなたは読み取り専用モードで動作しています。ファイルの読み取り、コード検索、シェルコマンドの実行は可能ですが、ファイルの編集や作成はできません。調査結果の報告のみ行ってください。

## レビュー依頼

### 対象
<何をレビューするか>

### 観点
<レビュー観点>

### 背景
<背景情報があれば>
PROMPT
)"
```

`--share` により完了時にセッション全体が `/tmp/copilot-review-latest.md` に markdown で保存される。

### 4. Present results

Bash ツールの timeout 内に完了した場合: 出力をそのまま表示する。

timeout した場合: AskUserQuestion で「Copilot がまだ実行中です。待ちますか?」と確認する。
待つ場合は `/tmp/copilot-review-latest.md` を定期的に読んで完了を待つ。

Copilot の出力を表示する際、冒頭に Copilot CLI による結果である旨を注記。

## Examples

```
/review-copilot-cli                                    # 会話の文脈からレビュー対象を判断
/review-copilot-cli staged -y                          # staged changes を確認スキップでレビュー
/review-copilot-cli この設計方針についてレビューして     # 方針レビュー
/review-copilot-cli src/auth.ts --model o3             # 特定ファイルをモデル指定でレビュー
/review-copilot-cli pr エラーハンドリングに注目         # PR 全変更をフォーカス指定でレビュー
```
