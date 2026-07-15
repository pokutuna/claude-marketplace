# codex

OpenAI Codex CLI に質問し、Claude Code から独立した AI の意見を得るプラグイン。

## Overview

- **ask-codex**: Codex にコードレビュー、設計相談、調査、質問を依頼する

`/ask-codex` は Codex の Auto 相当の権限で起動する。Codex はワークスペース内でファイル編集とコマンド実行を自動で行える。ワークスペース外への書き込みやネットワークアクセスは、Codex が必要に応じて承認を求める。

最終回答と、実行中の JSONL イベントログは `$TMPDIR`（未設定時は `/tmp`）に保存される。Claude Code 側の待機が timeout しても Codex プロセスは継続し、ログから進行状態を確認できる。Codex のセッションも保持するため、必要に応じて `codex exec resume --last` で再開できる。

既定のモデルと reasoning effort は `gpt-5.6-luna` と `xhigh`。`--model` と `--effort` で実行ごとに上書きできる。

## Prerequisites

- [Codex CLI](https://developers.openai.com/codex/cli/) (`codex` command)
- Codex CLI での認証済み状態

## Usage

```
/ask-codex staged -y                         # staged changes を確認スキップでレビュー
/ask-codex この設計方針についてレビューして     # 方針レビュー
/ask-codex src/auth.ts --model gpt-5.6-luna --effort max  # 特定ファイルをモデル・effort 指定でレビュー
/ask-codex PR のエラーハンドリングを確認して   # 現在の変更の観点指定レビュー
```

## Installation

```
/plugin install codex@pokutuna-plugins
```
