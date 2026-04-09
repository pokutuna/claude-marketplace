---
name: request-pr-review
description: >-
  Request GitHub Copilot review on a Pull Request.
  Use when: "request-pr-review", "PR レビュー依頼", "PR レビューリクエスト", "copilot review"
metadata:
  author: pokutuna
  version: 0.1.0
  compatibility: GitHub CLI (gh) installed and authenticated
allowed-tools:
  - Bash(gh pr view:*)
  - Bash(gh api */requested_reviewers)
---

# Request Copilot Review

PullRequest に GitHub Copilot のレビューをリクエストする。

<ARGUMENTS>
$ARGUMENTS
</ARGUMENTS>

## Arguments

- **PR**: PR 番号、PR URL、またはブランチ名。省略時は現在のブランチの PR を使用する

## Instructions

### 1. PR の特定

- `$ARGUMENTS` に PR 番号、URL、ブランチ名が指定されていればそれを使う
  - `gh pr view <pr> --json number,url -q '"\(.number) \(.url)"'`
- 指定がなければ、現在のブランチの PR を `gh pr view --json number,url -q '"\(.number) \(.url)"'` で取得する
- PR が見つからない場合はエラーメッセージを表示して終了する

### 2. Copilot レビューのリクエスト

`gh pr create` の `--reviewer` では bot を指定できないため、API を直接呼び出す。

**以下の 2 つのコマンドを別々に実行すること** (allowed-tools のパターンマッチのため):

1. PR 番号の確認:
   ```bash
   gh pr view --json number,url -q '"\(.number) \(.url)"'
   ```

2. レビュー依頼:
   ```bash
   gh api --method POST -f 'reviewers[]=copilot-pull-request-reviewer[bot]' \
     repos/{owner}/{repo}/pulls/{pr_number}/requested_reviewers
   ```
   - `{owner}/{repo}` は `gh repo view --json nameWithOwner -q .nameWithOwner` で取得する

### 3. 結果の表示

- 成功した場合: PR の URL とともに Copilot レビューをリクエストした旨を表示する
- 失敗した場合: エラー内容を表示する (リポジトリで Copilot レビューが有効でない可能性を示唆する)

## Examples

```
/request-pr-review                # 現在のブランチの PR に Copilot レビューをリクエスト
/request-pr-review 123            # PR #123 に Copilot レビューをリクエスト
```
