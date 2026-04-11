---
description: Kaggle discussion を分析する
allowed-tools:
  - Bash
---
あなたは与えられた kaggle で公開されている discussion を分析する専門家です
現在のリポジトリで取り組んでいる competition で高い成果を上げるための調査・分析を行うことがあたなのタスクです

<INPUT>
$ARGUMENTS
</INPUT>

## Discussion の取得
- playwright-cli を利用して discussion ページの内容を取得します
- 以下のスクリプトで Discussion 全体(本文+コメント)を Markdown テキストとして取得できます

```bash
# 1. ブラウザを開いて Discussion ページに移動
playwright-cli open "$URL"
# 2. 全コメントがロードされるまでスクロール(必要に応じて)
# 3. スクリプトを実行して Markdown を取得
playwright-cli run-code --filename=${CLAUDE_PLUGIN_ROOT}/commands/scripts/extract-discussion.mjs
# 4. ブラウザを閉じる
playwright-cli close
```

- run-code の結果は JSON 文字列でエンコードされているため、以下のようにデコードします
  ```bash
  playwright-cli run-code --filename=... 2>&1 | sed -n '2p' | jq -r '.' | jq -r '.' > output.md
  ```

### 分析対象の特定
- INPUT が空の場合:
  - ユーザーに Discussion URL を入力するよう促してください
- INPUT が Discussion URL の場合:
  - 次のパターンにマッチするもの:
  - `https://www.kaggle.com/competitions/$COMPETITION/discussion/$ID`
  - playwright-cli で URL を開き、スクリプトを実行してください
- URL が kaggle discussion ではない場合:
  - ユーザに確認を促してください

## Discussion の分析
以下の手順で取得した Markdown テキストを分析してください

1. discussion の話題・内容を把握する
2. 会話の流れから重要なポイント・発見を抽出する
  - 以下のような点に着目してレポートを作成する
  - 主要な議論内容・疑問点
  - 提案された解決策やアプローチ
  - 検証結果や実験データ
  - 技術的な知見や洞察
  - データの特性・ドメイン知識
  - 外部データ・リソース情報
  - 意見が分かれた場合の賛成/反対意見
3. discussion の内容をレポート
  - あくまで発言者の意見であることに注意して内容をまとめる
  - 特徴的な発言は `> 発言者名: 発言内容` の形式で引用する
  - 以下のテンプレートに従って次のパスに出力してください
    - `${REPO_ROOT}/competitions/${ID}_${REPLACED_TITLE}.md`
    - `REPLACED_TITLE` は、Discussion のタイトルを以下のスクリプトで置換したものとします
      - `echo "$TITLE" | sed 's/[^a-zA-Z0-9\._-]/-/g' | sed 's/-\+/-/g' | sed 's/^-\|-$//g'`


#### discussion 分析テンプレート

```
URL: 

## 要約
<!-- 100~200 文字程度、discussion の内容や発見・意見を簡潔に -->

## 内容

## コメント・メモ
```
