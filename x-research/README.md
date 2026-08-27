# x-research

xAI Grok API の `x_search` サーバーサイドツールで X (Twitter) を調査するプラグイン。
調査結果のレポートに加えて、**根拠となるポストの原文引用と URL** を返す。

## Overview

- **x-research**: 依頼から Grok への調査プロンプトを組み立て、実行前にユーザーに
  確認し、検証済み出典付きのレポートを返す skill

skill の仕事はプロンプトを書くことである。「何を調べ、どんな語で探し、各知見に
何を記録するか」を Grok への指示として書き下ろす。調査の型は依頼ごとにプロンプトで
決まるため、技術情報の収集にも評判調査にも同じ経路で対応できる。

出力の構造は依頼によらず一定である:

| フィールド | 内容 |
|-----------|------|
| `report` | 依頼への回答 (Markdown) |
| `findings[].point` / `detail` | 個々の知見と、依頼が指定した記録項目 |
| `findings[].sources[]` | 裏付けとなるポストの URL・投稿者・日付・**原文引用** |
| `findings[].links[]` | ポストが指す論文・リポジトリ・モデルカード等の URL |

`x_search` は生の検索 API ではなく、xAI サーバー側で回るエージェントループ。
モデルが本文に書く URL は捏造されうるため、このプラグインは API が実際に収集した
citations と照合し、裏付けのない URL を `dropped_unverified_urls` に隔離する
(引用ごと除去する)。根拠として認めるのは X のポスト URL のみで、エージェントが
閲覧したニュース記事などが X 上の発言の裏付けに化けることを防ぐ。

さらに `sourcing` に出典の健全性を出す。モデルがツールを呼ばずに答えてもスキーマは
埋まるため、`search_call_count` (検索を実行した回数)、`x_citation_count`
(X ポストの引用数)、`unsourced_findings` (検証を通った根拠がない知見) を見て、
モデル知識からの合成をそれと判別する。

## Prerequisites

- [uv](https://docs.astral.sh/uv/) (スクリプトは PEP 723 形式)
- `XAI_API_KEY`: [console.x.ai](https://console.x.ai) で作成 (サブスク不要)
  - プリペイドクレジットを少額 ($5〜) 手動購入する。invoiced billing limit は
    $0 のままにしておくと、残高切れでリクエストが拒否されるだけで請求は伸びない

## Usage

```
/x-research ASR の新しいモデルや論文、日本語対応のものを今月分
```

スクリプト単体でも使える (プロンプトは自分で書く):

```bash
uv run skills/x-research/scripts/search.py \
  --prompt-file prompt.txt \
  --from 2026-08-01 --to 2026-08-27
```

## Cost

**既定 (grok-4.3 / `--max-turns 5`) で 1 クエリ $0.5-0.8**。トークン単価と
公開されているツール単価 ($5/1,000 calls) から計算した額の 8 倍近くが実際に
請求される (差分は x_search のツール課金で、原因は未特定)。見積もりを計算で
出さず、実額は出力 JSON の `usage.cost_in_usd_ticks / 1e9` で毎回確認する。

コストは `--max-turns` (エージェントループの上限) にほぼ比例する
(`--max-turns 2` で $0.4 前後、`10-12` で $0.8-1.0)。何回検索すれば足りるかは
話題のポスト量で決まり事前には分からないので、skill は既定の 5 で実行し、
カバレッジが不足していれば値を上げた再実行を追加コストとともに提案する。

`--model` で上位モデル (grok-4.5 / 4.6) を指定すると、検索を深く回す分コストが
一桁上がりうる。既定のまま使うことを推奨する。

`--previous-response-id` による追い質問は安い ($0.18) が、**citations が引き継がれず
出典検証が効かない** (実測)。深掘りも新規検索で行う。

## Notes

- 結果はサンプリングに基づく傾向であり、悉皆調査ではない (recall 非保証)
- ポスト本文やエンゲージメント数が必要な場合のみ X API (別勘定) で hydrate する
- API 仕様の詳細は `skills/x-research/references/xai-api.md`
