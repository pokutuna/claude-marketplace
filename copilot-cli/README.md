# copilot-cli

Ask GitHub Copilot CLI to review code, design, or approach — get a second AI opinion.

## Overview

GitHub Copilot CLI にレビューを依頼するプラグイン。
Claude が会話コンテキストや引数からレビュープロンプトを構築し、ユーザー確認後に Copilot を実行して結果を表示する。
コードレビューだけでなく、設計方針やアプローチのレビューにも対応。

## Prerequisites

- GitHub Copilot CLI installed (`copilot` command available)
- Authenticated: `copilot login`

## Usage

```
/review-copilot-cli                                    # 会話の文脈からレビュー対象を判断
/review-copilot-cli staged -y                          # staged changes を確認スキップでレビュー
/review-copilot-cli この設計方針についてレビューして     # 方針レビュー
/review-copilot-cli src/auth.ts --model o3             # 特定ファイルをモデル指定でレビュー
```

## Options

| Option | Description |
|--------|-------------|
| `--model <model>` | Copilot のモデルを指定 (default: gpt-5.4) |
| `--effort <level>` | 推論レベル: low/medium/high/xhigh (default: high) |
| `-y`, `--yes` | 確認プロンプトをスキップ |

## Installation

```
/plugin install copilot-cli@pokutuna-plugins
```
