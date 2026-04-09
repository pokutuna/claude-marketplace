# github-copilot

GitHub Copilot CLI integration — second AI opinion and PR review requests.

## Overview

GitHub Copilot CLI を活用するプラグイン。
- **ask-copilot**: Copilot にレビューや質問を依頼し、独立した AI の意見を得る
- **request-pr-review**: PR に Copilot のレビューをリクエストする

## Prerequisites

- [GitHub Copilot CLI](https://github.com/github/copilot-cli) (`copilot` command)
  - Authenticated: `copilot login`
  - Used by: `/ask-copilot`
- [GitHub CLI](https://cli.github.com/) (`gh` command)
  - Authenticated: `gh auth login`
  - Used by: `/request-pr-review`

## Usage

```
/ask-copilot                                    # 会話の文脈からレビュー対象を判断
/ask-copilot staged -y                          # staged changes を確認スキップでレビュー
/ask-copilot この設計方針についてレビューして     # 方針レビュー
/ask-copilot src/auth.ts --model o3             # 特定ファイルをモデル指定でレビュー
/request-pr-review                                 # 現在のブランチの PR に Copilot レビューをリクエスト
/request-pr-review 123                             # PR #123 に Copilot レビューをリクエスト
```

## Installation

```
/plugin install github-copilot@pokutuna-plugins
```
