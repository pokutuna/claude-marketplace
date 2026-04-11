# kaggle-helper

Kaggle のコンペティションリサーチを支援する Claude Code プラグイン。

## Skills

| Skill | Description |
|-------|-------------|
| `meta-kaggle` | kaggle/meta-kaggle データセットをダウンロードし、コンペ別にディスカッションを検索・分析 |

## Commands

| Command | Description |
|---------|-------------|
| `/kaggle-discussion` | Kaggle discussion を取得・分析し、レポートを出力 |
| `/kaggle-notebook` | Kaggle notebook を取得・分析し、レポートを出力 |

## Prerequisites

- kaggle CLI (`pip install kaggle`) - 認証済み
- playwright-cli - Discussion ページの取得に使用
- uv - Python スクリプト実行 (meta-kaggle skill)

## Installation

```
/plugin install kaggle-helper@pokutuna-plugins
```
