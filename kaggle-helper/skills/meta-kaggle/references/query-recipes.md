# Query Recipes

`SCRIPT` は `uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/meta-kaggle/scripts` のエイリアスとして記載。

## 上位解法の write-up を得る

最も典型的なユースケース。2つの方法がある。

**方法 1: WriteUpForumTopicId (正確・推奨)**

Teams テーブルの `WriteUpForumTopicId` は、チームが公式に登録した解法 write-up のトピック ID。
順位と直接紐づくため最も正確。ただし全チームが登録するわけではない。

```bash
SCRIPT/query.py <slug> sql "
  SELECT t.PrivateLeaderboardRank as Rank, t.TeamName, t.Medal,
         tp.Id as TopicId, tp.Title, tp.Score
  FROM teams t
  JOIN topics tp ON t.WriteUpForumTopicId = tp.Id
  WHERE t.WriteUpForumTopicId IS NOT NULL
  ORDER BY t.PrivateLeaderboardRank
  LIMIT 10
"
```

**方法 2: solutions サブコマンド (タイトルパターンマッチ)**

"solution", "1st place", "gold" 等のキーワードでトピックタイトルを検索。
WriteUp 未登録の解法も拾えるが、ノイズが混じる場合がある。

```bash
SCRIPT/query.py <slug> solutions --limit 10
```

**実践**: まず方法 1 で取得し、不足していれば方法 2 で補完する。

## Discussion 分析

### Upvote の多いトピック
```bash
SCRIPT/query.py <slug> topics --sort score --limit 20
```

### コメントの多いトピック
```bash
SCRIPT/query.py <slug> topics --sort messages --limit 20
```

### 前回分析以降に更新があったトピック (差分チェック)
```bash
SCRIPT/query.py <slug> topics --updated-since 2025-04-01 --sort updated
```

### 指定日以降に作成された新規トピック
```bash
SCRIPT/query.py <slug> topics --since 2025-04-01 --sort created
```

オプションは組み合わせ可能。例: 4/1 以降に更新があった "eda" を含むトピック:
```bash
SCRIPT/query.py <slug> topics --updated-since 2025-04-01 --search "eda" --sort updated
```

## メダルを獲得したメッセージの検索

```bash
SCRIPT/query.py <slug> sql "
  SELECT m.Id, m.ForumTopicId, t.Title, m.Medal, m.PostDate
  FROM messages m JOIN topics t ON m.ForumTopicId = t.Id
  WHERE m.Medal IS NOT NULL
  ORDER BY m.Medal, m.PostDate
"
```

## 上位チームの一覧

```bash
SCRIPT/query.py <slug> sql "
  SELECT PrivateLeaderboardRank as Rank, TeamName, Medal
  FROM teams
  WHERE PrivateLeaderboardRank IS NOT NULL
  ORDER BY PrivateLeaderboardRank
  LIMIT 20
"
```
