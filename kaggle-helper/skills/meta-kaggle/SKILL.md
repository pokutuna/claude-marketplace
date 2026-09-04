---
name: meta-kaggle
description: 終了済みコンペの discussion・チーム情報を meta-kaggle から検索・分析（終了前のコンペは対象外）。"meta-kaggle", "上位解法" などで起動。
allowed-tools:
  - "Bash(uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/meta-kaggle/scripts/sync.py *)"
  - "Bash(uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/meta-kaggle/scripts/extract.py *)"
  - "Bash(uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/meta-kaggle/scripts/query.py *)"
  - "Read(~/.meta-kaggle/**)"
  - "Edit(~/.meta-kaggle/**)"
  - AskUserQuestion
user-invocable: true
---

# meta-kaggle Skill

kaggle/meta-kaggle データセットからコンペティションのディスカッション・チーム情報を検索・分析する。

## Prerequisites

- kaggle CLI (`pip install kaggle`) — 認証済み (`~/.kaggle/kaggle.json`)
- uv — Python スクリプト実行
- duckdb — query.py の依存 (uv が自動インストール)

## Instructions

3段階のワークフローで進める。初回は Step 1 から、2回目以降はデータが同期済みか確認してから Step 2 or 3 へ。

### Step 1: データ同期

ソース CSV を `~/.meta-kaggle/` にダウンロードする。

```bash
# 状態確認 (ダウンロード済みか、最新か)
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/meta-kaggle/scripts/sync.py --status

# 同期 (未ダウンロードまたは更新がある場合のみダウンロード)
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/meta-kaggle/scripts/sync.py

# 強制再ダウンロード
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/meta-kaggle/scripts/sync.py --force
```

成功すると JSON サマリが出力される。対象: Competitions.csv, Teams.csv, Forums.csv, ForumTopics.csv, ForumMessages.csv

### Step 2: コンペ別サブセット作成

コンペの slug を指定してフォーラムデータを Parquet に抽出する。

```bash
# サブセット作成 (コンペの Discussion タブのみ、デフォルト)
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/meta-kaggle/scripts/extract.py <competition-slug>

# データセット・モデルのフォーラムも含める
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/meta-kaggle/scripts/extract.py <competition-slug> --include-datasets --include-models

# 再作成 (データ更新後、オプション変更時)
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/meta-kaggle/scripts/extract.py <competition-slug> --update

# 作成済み一覧
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/meta-kaggle/scripts/extract.py --list
```

デフォルトではコンペの Discussion タブ (ParentForumId: 5, 8, 52) のみ抽出する。関連データセットやモデルのフォーラムも含めたい場合は `--include-datasets` / `--include-models` を指定する。

成功すると `~/.meta-kaggle/<slug>/` に teams.parquet, topics.parquet, messages.parquet, meta.json が作成される。

### Step 3: クエリ・探索

サブセットに対して DuckDB で検索する。全サブコマンドに `--limit N` オプションあり (デフォルト 50)。

**トピック一覧と検索:**
```bash
# トピック一覧 (Score 降順, デフォルト)
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/meta-kaggle/scripts/query.py <slug> topics

# ソート: score(デフォルト), messages, created, updated
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/meta-kaggle/scripts/query.py <slug> topics --sort updated

# タイトル検索 + 日付フィルタ (組み合わせ可)
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/meta-kaggle/scripts/query.py <slug> topics --search "keyword" --since 2025-04-01

# 指定日以降にコメントが付いたトピック
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/meta-kaggle/scripts/query.py <slug> topics --updated-since 2025-04-01 --sort updated
```

**スレッド読み込みと検索:**
```bash
# スレッドを Markdown 形式で読む (返信関係付き)
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/meta-kaggle/scripts/query.py <slug> thread <topic_id>

# メッセージ本文をキーワード検索
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/meta-kaggle/scripts/query.py <slug> search "keyword"
```

**解法・チーム情報:**
```bash
# 上位解法トピック (タイトルパターンマッチ)
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/meta-kaggle/scripts/query.py <slug> solutions

# スキーマ確認
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/meta-kaggle/scripts/query.py <slug> schema

# 任意の SQL (テーブル: teams, topics, messages)
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/meta-kaggle/scripts/query.py <slug> sql "SELECT ..."
```

**上位解法の取得 (推奨手順):**

1. まず WriteUpForumTopicId 経由で正確な解法を取得:
```bash
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/meta-kaggle/scripts/query.py <slug> sql "
  SELECT t.PrivateLeaderboardRank as Rank, t.TeamName, t.Medal,
         tp.Id as TopicId, tp.Title, tp.Score
  FROM teams t JOIN topics tp ON t.WriteUpForumTopicId = tp.Id
  WHERE t.WriteUpForumTopicId IS NOT NULL
  ORDER BY t.PrivateLeaderboardRank LIMIT 10
"
```
2. 不足していれば `solutions` サブコマンドで補完
3. `thread <topic_id>` で本文を読む

詳細なレシピは `references/query-recipes.md` を参照。
スキーマやデータモデルの詳細は `references/schema.md` を参照。

## Examples

### 上位解法を調べる

```
ユーザ: map-charting-student-math-misunderstandings の上位解法を調べて

手順:
1. sync.py --status -> データが同期済みか確認 (初回は sync.py で DL)
2. extract.py map-charting-student-math-misunderstandings -> サブセット作成
3. query.py <slug> sql "SELECT ... FROM teams t JOIN topics tp ON t.WriteUpForumTopicId = tp.Id ..."
   -> WriteUp 登録済みの上位解法トピック一覧を取得
4. 件数が不足していれば query.py <slug> solutions で補完
5. query.py <slug> thread <topic_id> -> 各解法の本文を読む
```

### 特定の手法が使われているか調べる

```
ユーザ: このコンペで TabPFN を使った人はいる?

手順:
1. extract.py <slug> (未作成の場合)
2. query.py <slug> search "TabPFN"
   -> TabPFN に言及しているメッセージとトピックの一覧
3. query.py <slug> thread <topic_id> -> 該当スレッドの詳細を読む
```

### Discussion の差分チェック

```
ユーザ: 昨日から更新のあった discussion を確認して

手順:
1. extract.py <slug> --update -> サブセットを最新化
2. query.py <slug> topics --updated-since 2025-04-04 --sort updated
   -> 昨日以降にコメントが付いたトピック
3. query.py <slug> topics --since 2025-04-04 --sort created
   -> 昨日以降に新規作成されたトピック
4. 気になるトピックを query.py <slug> thread <topic_id> で読む
```

## Troubleshooting

### Error: "not_extracted"

原因: 指定した slug のサブセットが未作成。
対処: `extract.py <slug>` を実行する。初回は `sync.py` でソースデータのダウンロードも必要。

### Error: "data_missing"

原因: ソース CSV がダウンロードされていない。
対処: `sync.py` を実行してデータを同期する。

### Error: "no_forum" / ForumId が NULL

原因: 開催中のコンペの Discussion データは meta-kaggle に含まれない (Kaggle 公式仕様)。リーダーボードが確定した終了済みコンペのみ対象。
対処: 開催中のコンペの Discussion を調べるには Kaggle Web やブラウザから直接取得する。

### Error: "ambiguous_slug"

原因: 部分一致で複数のコンペがヒットした。
対処: 返された `candidates` から正しい slug を特定して再実行する。

### データが古い / 最新の Discussion が含まれない

原因: meta-kaggle は毎日 UTC 12時頃に更新される (データ鮮度は UTC 7-8時頃まで)。
対処:
1. `sync.py --status` で `lastUpdated` を確認
2. `sync.py` で最新データに同期
3. `extract.py <slug> --update` でサブセットを再作成

### topics コマンドで低品質トピックが多い

原因: デフォルトでは Score <= 0 かつ TotalMessages <= 1 のトピックを除外している。
対処: `--all` で全トピック表示、`--min-score N` や `--min-messages N` で閾値を指定。
