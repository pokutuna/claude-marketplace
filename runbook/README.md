# runbook

実行者に判断を残さない runbook を書くための Claude Code プラグイン。

RUNBOOK を実行するのは、書いた本人ではない。同僚かもしれないし、別の SubAgent かもしれない。
その人にシステムの知識があるとは限らず、書いた側に問い合わせる手段もない。

このプラグインは、手順に必要な判断を書く時点で決着させる方向に働く。
決めきれないことは依頼者に尋ね、事前に決められない条件は「何を観測してどちらへ進むか」の分岐にする。
「適切に判断する」「確認事項」「TBD」のような、実行時の判断を実行者に預ける書き方を避ける。

## Skills

| Skill | Description |
|-------|-------------|
| `write-runbook` | runbook や作業依頼の作成・レビュー |

## Installation

```
/plugin install runbook@pokutuna-plugins
```
