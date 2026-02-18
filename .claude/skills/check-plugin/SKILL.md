---
name: check-plugin
description: プラグインの構成をチェックする。"check-plugin", "プラグインをチェック", "validate plugin" で起動。
allowed-tools:
  - Bash(uv run *)
  - Read
  - Glob
  - Grep
---

# check-plugin

プラグインの構成が正しいかチェックする。

## 手順

1. 対象の決定
   - `$ARGUMENTS` が指定されていれば、そのプラグインのみチェックする
   - 指定がなければ全プラグインをチェックする

2. バリデーションスクリプトを実行する

```bash
uv run --script ${SKILL_ROOT}/scripts/check-plugin.py <repo-root> [<plugin-name>]
```

3. スクリプトの出力を確認し、NG がある場合は修正方法を具体的に提案する

4. スクリプトではチェックできない以下の項目を目視で確認し、改善点があれば提案する:
   - SKILL.md の description にトリガーワードが含まれているか
   - description の内容がスキルの機能を適切に説明しているか
