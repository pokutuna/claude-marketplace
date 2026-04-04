# Data Model & Schema Reference

## Source Data Relations (meta-kaggle)

Forums はコンペ・データセット・モデル共通の汎用ディスカッションシステム。

```
Competitions.ForumId -> Forums.Id          コンペのフォーラム (NULL の場合あり)
Teams.CompetitionId  -> Competitions.Id    コンペのチーム
Forums.ParentForumId -> Forums.Id          フォーラム階層 (自己参照)
ForumTopics.ForumId  -> Forums.Id          トピック -> フォーラム
ForumMessages.ForumTopicId -> ForumTopics.Id  メッセージ -> トピック
Teams.WriteUpForumTopicId  -> ForumTopics.Id  上位チームの解法 write-up トピック
```

Forums の ParentForumId によるカテゴリ:
- `Id=5` "Active Competitions"
- `Id=8` "Past Competitions"
- `Id=52` "Kaggle in Class"
- `Id=1023` "Public Datasets"
- `Id=2578766` "Models"

## Subset Schema

### teams (Teams -> コンペのチーム・順位情報)

| Column | Type | Description |
|--------|------|-------------|
| Id | BIGINT | チーム ID |
| CompetitionId | BIGINT | コンペ ID |
| TeamLeaderId | BIGINT | チームリーダーの User ID |
| TeamName | VARCHAR | チーム名 |
| ScoreFirstSubmittedDate | VARCHAR | 初回提出日 |
| LastSubmissionDate | VARCHAR | 最終提出日 |
| PublicLeaderboardSubmissionId | BIGINT | Public LB の提出 ID |
| PrivateLeaderboardSubmissionId | BIGINT | Private LB の提出 ID |
| IsBenchmark | BOOLEAN | ベンチマークかどうか |
| Medal | BIGINT | メダル (1=Gold, 2=Silver, 3=Bronze, NULL=なし) |
| MedalAwardDate | DATE | メダル授与日 |
| PublicLeaderboardRank | BIGINT | Public LB 順位 |
| PrivateLeaderboardRank | BIGINT | Private LB 順位 |
| WriteUpForumTopicId | BIGINT | 解法 write-up の ForumTopic ID (あれば) |

### topics (ForumTopics -> ディスカッションスレッド)

| Column | Type | Description |
|--------|------|-------------|
| Id | BIGINT | トピック ID |
| ForumId | BIGINT | フォーラム ID |
| KernelId | BIGINT | 紐づく Notebook ID (あれば) |
| FirstForumMessageId | BIGINT | 最初のメッセージ ID |
| LastForumMessageId | BIGINT | 最後のメッセージ ID |
| CreationDate | VARCHAR | 作成日 (MM/DD/YYYY HH:MM:SS) |
| LastCommentDate | VARCHAR | 最終コメント日 |
| Title | VARCHAR | トピックタイトル |
| IsSticky | BOOLEAN | 固定トピックか |
| TotalViews | BIGINT | 閲覧数 |
| Score | BIGINT | スコア (upvote - downvote) |
| TotalMessages | BIGINT | メッセージ数 |
| TotalReplies | BIGINT | 返信数 |

### messages (ForumMessages -> 個別メッセージ)

| Column | Type | Description |
|--------|------|-------------|
| Id | BIGINT | メッセージ ID |
| ForumTopicId | BIGINT | トピック ID |
| PostUserId | BIGINT | 投稿者 User ID |
| PostDate | VARCHAR | 投稿日 |
| ReplyToForumMessageId | VARCHAR | 返信先メッセージ ID |
| Message | VARCHAR | 本文 (HTML) |
| RawMarkdown | VARCHAR | 本文 (Markdown) — こちらを優先して使う |
| Medal | BIGINT | メダル (1=Gold, 2=Silver, 3=Bronze) |
| MedalAwardDate | DATE | メダル授与日 |

## Date Format Note

日付カラムは `MM/DD/YYYY HH:MM:SS` 形式の VARCHAR。文字列比較ではソートできない。
DuckDB では `strptime(col, '%m/%d/%Y %H:%M:%S')` でパースして比較すること。

## Dataset Update Timing

- ソースデータセット (kaggle/meta-kaggle) は **毎日 UTC 12時頃 (JST 21時頃)** に更新される
- データの鮮度は **UTC 7-8時頃まで** のスナップショット (更新時刻の数時間前のデータ)
- 全テーブル (Competitions, Teams, Forums, ForumTopics, ForumMessages) が同時に更新される
- sync.py は `lastUpdated` で更新有無を判定し、**ファイルサイズ比較で差分のあるファイルのみ**ダウンロードする
- `~/.meta-kaggle/metadata.json` にダウンロード時刻と各ファイルの `size`, `creationDate` を保存している

## Known Limitations

- **Competitions.ForumId が NULL**: 約半数のコンペで NULL。extract.py は Forums.Title から slug/タイトルマッチでフォールバック検索するが、見つからない場合がある
- **データは完全ダンプではない**: Kaggle 公式が明記。一部の行・列がフィルタされている
- **ハッシュ値は提供されない**: Kaggle API はファイルの `name`, `size`, `creationDate` のみ返す。サイズ比較で差分判定している
