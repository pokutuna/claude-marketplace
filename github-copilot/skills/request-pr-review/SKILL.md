---
name: request-pr-review
description: Request GitHub Copilot review on a Pull Request. "PR レビュー依頼", "copilot review" などで起動。
argument-hint: "[pr-number | url | branch]"
metadata:
  author: pokutuna
  compatibility: GitHub CLI (gh) v2.88.0+ installed and authenticated
allowed-tools:
  - Bash(gh pr view*)
  - Bash(gh pr edit*)
---

# Request Copilot Review

PullRequest に GitHub Copilot のレビューまたは再レビューをリクエストする。

<ARGUMENTS>
$ARGUMENTS
</ARGUMENTS>

## Arguments

- **PR**: PR 番号、PR URL、またはブランチ名。省略時は現在のブランチの PR を使用する

## Instructions

### 1. PR の特定

- `$ARGUMENTS` に PR 番号、URL、ブランチ名が指定されていればそれを使う
- 指定がなければ、現在のブランチの PR を使う
- `gh pr view <pr> --json number,url -q '"\(.number) \(.url)"'` で PR の存在を確認する (引数なしなら `<pr>` を省略)
- PR が見つからない場合はエラーメッセージを表示して終了する

### 2. Copilot レビューのリクエスト

```bash
gh pr edit <pr> --add-reviewer @copilot
```

### 3. 結果の表示

- 成功した場合: PR の URL とともに Copilot レビューをリクエストした旨を表示する
- 失敗した場合: エラー内容を表示する (リポジトリで Copilot レビューが有効でない可能性を示唆する)

## Examples

```
/request-pr-review                # 現在のブランチの PR に Copilot レビューをリクエスト
/request-pr-review 123            # PR #123 に Copilot レビューをリクエスト
```
