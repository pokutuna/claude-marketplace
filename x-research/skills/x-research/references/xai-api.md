# xAI API reference for x_search research

docs.x.ai (2026-08-27 取得) に基づく。各ページは URL 末尾に `.md` を付けると
Markdown で取得できる (例: `https://docs.x.ai/developers/tools/x-search.md`)。

## エンドポイントと最小リクエスト

Responses API: `POST https://api.x.ai/v1/responses` (認証: `Authorization: Bearer $XAI_API_KEY`)

```json
{
  "model": "grok-4.3",
  "input": [{"role": "user", "content": "..."}],
  "tools": [{"type": "x_search"}]
}
```

x_search はサーバーサイドで回るエージェントループであり、単発の検索 API ではない。
検索の生結果 (ポスト本文の配列) は API レスポンスに返らず、モデルが内部で消費して
最終回答を組み立てる。API の粒度は `x_search` 1 個で、内部サブツール
(`x_keyword_search` / `x_semantic_search` / `x_user_search` / `x_thread_fetch`) を
単体で呼ぶ口はない。

## x_search パラメータ

| パラメータ | 説明 |
|-----------|------|
| `allowed_x_handles` | このハンドルのポストのみ対象 (最大 20、`excluded_x_handles` と併用不可) |
| `excluded_x_handles` | このハンドルのポストを除外 (最大 20) |
| `from_date` / `to_date` | ISO8601 (`YYYY-MM-DD`)。ドキュメントは「両端含む」だが、実装 (grok-build の tool_overrides.rs) では `to_date` はその日の 00:00 UTC 排他。最終日を含めたいなら翌日を指定する |
| `enable_image_understanding` | ポスト内画像の解析 (画像トークン課金が増える) |
| `enable_video_understanding` | ポスト内動画の解析 (X Search 限定) |

ハンドルは `@` を付けない。typo は静かに失敗する (エラーにならない)。

呼び出し側が指定できるのはこの 6 個だけで、`limit` / `mode` (Top/Latest) /
`min_score_threshold` / ソート順は**サブツール層にしかなく、モデルが決める**。
プロンプトで希望を伝えることはできても、API で固定はできない。

`from_date` / `to_date` は `x_user_search` と `x_thread_fetch` には効かない
(grok-build の acp_agent.rs でテストごと固定されている)。期間指定をしても、
ユーザー検索やスレッド取得の経路からは範囲外のポストが入りうる。

## 検索演算子はサブツールの query に効く

型付きパラメータ (`allowed_x_handles` 等) とは別に、`x_keyword_search` の `query`
文字列が X advanced search の演算子を解する。プロンプトに書いた演算子をモデルが
内部クエリに使うことは、記録された実 API の SSE ストリーム
(vercel/ai の `packages/xai/src/responses/__fixtures__/xai-x-search-tool.chunks.txt`)
で確認できる:

```json
{"name":"x_keyword_search","input":"{\"query\":\"from:xai filter:media\",\"limit\":20,\"mode\":\"Latest\"}"}
```

サブツールのスキーマ (leak 由来、複数ソースで一致) が挙げる演算子:

`from: to: @user list:` / `since: until: within_time:Xd since_id: max_id:` /
`min_faves:N min_retweets:N min_replies:N filter:has_engagement` /
`filter:links media images videos news replies quote self_threads` /
`url:domain` / `"完全一致"` `OR` (大文字必須) `-除外` `()`

落とし穴:

- **`lang:ja` はスキーマに存在しない**。X の web 検索では有効だがモデルは
  存在を知らず自発的に使わない。言語制御はクエリ語自体を日本語にする
- `min_likes:` / `min_reposts:` は X API v2 の綴りでスキーマにない。
  **`min_faves:` / `min_retweets:`** を使う
- `-filter:retweets` もスキーマにない (`-filter:replies` は否定規則で有効)
- 日本語圏の技術系ポストは母数が少なく、`min_faves:100` 程度でほぼ消える
- サブツールの `limit` は既定 3・最大 10 (ただし実ストリームでは 20 が観測され、
  API 側の上限は異なる可能性がある)。`mode` は `Top` / `Latest` (先頭大文字)

プロンプトに書いた演算子がそのまま `query` に載ることは実測で確認済み
(`since:` `until:` `filter:links` `url:arxiv.org` が発行クエリに出現し、
「日本語クエリに `min_faves:` を付けない」という自然文の指示も守られていた)。
出力 JSON の `search_calls` に実際に発行されたクエリが入るので、毎回確認できる。
ただし遵守は毎回保証されるものではない。

**絶対に守らせたい制約は型付きパラメータ、それ以外は演算子**で表現する。
エンゲージメント絞り込みには型付きパラメータがないため、演算子しか手段がない
(旧 Live Search API の `post_favorite_count` は x_search では削除された)。
両層の相互作用 (AND か上書きか) は未検証。

## citations (出典の ground truth)

- `response.citations`: エージェントが検索過程で見た全ソース URL のリスト。
  ただし**実測 (grok-4.3) ではトップレベルに現れなかった** — 2 回の実行とも
  citations は全て `annotations` 側から回収された。存在を前提にしないこと
- inline citations: Responses API ではデフォルト有効。本文に `[[N]](url)` 形式で
  埋め込まれ、`output_text` ブロックの `annotations` 配列に
  `{type: "url_citation", url, start_index, end_index, title}` が入る
  (インデックスは Python スライス規約)。無効化は `include: ["no_inline_citations"]`
- モデルが本文に書いた URL は捏造されうる。**citations / annotations 側が ground
  truth** であり、モデル出力の URL は status ID で照合して検証する
- xAI Python SDK (gRPC) では `inline_citations` が `x_citation` / `web_citation` に
  型分離されている。Responses API の `annotations` にはこの区別がない

### 逐語引用は明示しないと得られない

記録された実ストリームの最終出力では、モデルは要約・閲覧数・Post ID を並べる
一方で**逐語引用はゼロ**、本文中のインライン引用 `[[N]](url)` も出していなかった
(annotations は存在するのに)。原文の引用が必要なら、プロンプトで明示的に
要求する必要がある。

また X の citation URL は `https://x.com/i/status/<id>` 形式で**ハンドル名を
含まない**。誰の発言かを出すには、モデルに `author_handle` を書かせるしかない。

### ツール呼び出しの出力は暗号化されている

`x_search` と `web_search` の**出力内容はデフォルトで暗号化**され、呼び出し側から
読めない (xai-sdk-python の `examples/sync/server_side_tools.py` にコメントで明記。
`include: ["code_execution_call_output"]` を code_execution にだけ付けているのは
このため)。

`include` に渡せる値は実測で以下の 2 つだけだった (grok-4.3、curl で全数確認):

| 値 | 結果 |
|----|------|
| `no_inline_citations` | 200 |
| `reasoning.encrypted_content` | 200 |
| `verbose_streaming` | **400** `Argument not supported` |
| `inline_citations` | **400** |
| `x_search_call_output` | **400** (gRPC の `IncludeOption` にはあるが HTTP では不可) |

**モデルが実際に投げた検索クエリは `include` なしで取得できる**。出力アイテムの
`custom_tool_call` にクエリと `mode` が入っており、これを `search_calls` として
出力している。演算子が効いているかの監査はこれで足りる。

出力が暗号化されている以上、**ポスト URL の回収元は citations / annotations で
あり**、ツール呼び出し item から URL を拾う経路が単独で成立するとは期待できない。

また、実際のストリームでは X のサブツール呼び出しは `x_search_call` ではなく
**`custom_tool_call`** として現れ、`name` が `x_keyword_search` などになる
(call id は `xs_call_...`)。出力 item を型で判定するコードは、両方の形を
受け付ける必要がある。

### 出典の健全性判定

x_search はサーバーサイドのエージェントループなので、モデルがツールを呼ばずに
自分の知識で答えることがある。その場合でもスキーマは埋まり、`findings` は
自信ありげな `point` を持つ。「検索が空振りなら findings も空になるはず」という
期待は成り立たない。

スキーマ自体は正直な空回答 (`findings: []` + coverage_note で説明) を許しており、
system prompt でもそう指示している。つまり捏造はスキーマに強制された結果ではなく、
指示への不服従である。構造化されているぶん `unsourced_findings` として機械的に
検出できる。

そのため出力側で 3 つの指標を見る:

- **`search_call_count`**: エージェントが X 検索を実際に呼んだ回数。0 なら
  モデル知識だけで答えている
- **`x_citation_count` が 0**: X ポストが 1 件も引用されていない。引用付きの
  X 調査結果としては提示できない。ただし `search_call_count` が 1 以上なら、
  捏造ではなく citations の回収に失敗している可能性があるため、生レスポンスを
  確認してから判断する
- **`unsourced_findings`**: 検証を通った根拠ポストがない知見。ツール未呼び出しの
  捏造も、引用はあるが個々の知見が裏付けられていない状態も、ここに現れる

これらは別の失敗を捕まえる。引用数だけでは「引用 3 件で知見 10 個」を見逃し、
`unsourced_findings` だけでは「非 X の URL が知見を裏付けたことになっている」
状態を見逃す。

### 検証は X ポストに限る

有効な根拠として扱えるのは status ID を持つ X URL だけである。citations には
エージェントが閲覧したニュース記事なども含まれるため、それを許すと X 上の発言に
関する主張が X ポストゼロのまま検証を通過してしまう。

## Structured Outputs との併用

サーバーサイドツールと structured outputs は併用できる (Grok 4 系のみ)。
Responses API では `text.format` に指定する:

```json
"text": {"format": {"type": "json_schema", "name": "...", "schema": {...}, "strict": true}}
```

`strict: true` では全オブジェクトに `additionalProperties: false` と全キーの
`required` が必要。

## max_turns とコスト構造

- `max_turns` はエージェントループの assistant ターン数の上限 (ツール呼び出し数の
  直接の上限ではない。1 ターンで複数ツールが並列に呼ばれうる)。未指定時は
  サーバー側のグローバル上限が適用される
- 公式目安: quick lookup 1-2 / balanced 3-5 / deep research 10+
- `prompt_tokens` はループ内全推論の累積入力 (履歴込みで増加)、
  `completion_tokens` は最終出力のみ、`reasoning_tokens` は内部思考分
- `tool_calls` は失敗を含む全試行、`server_side_tool_usage` は成功分のみの
  カテゴリ別カウントで、**課金は後者のみ**
  (例: `{"SERVER_SIDE_TOOL_X_SEARCH": 3}`)

## 料金

トークン単価は `GET /v1/language-models/<id>` で取得できる (`prompt_text_token_price`
は 1M あたりの 1/10,000 セント単位。12500 → $1.25/1M)。以下は API から取得した実値:

| モデル | 入力/1M | 出力/1M |
|--------|---------|---------|
| grok-4.6 | $2.00 | $6.00 |
| grok-4.5 | $2.00 | $6.00 |
| grok-4.3 | $1.25 | $2.50 |
| grok-4.20-multi-agent | $1.25 | $2.50 |

- プロンプトが 200k トークン以上になるとリクエスト全体が倍額
- ツール課金: x_search / web_search / code_execution は $5 / 1,000 calls (成功分のみ)
- 画像/動画理解 (`view_image` / `view_x_video`) は呼び出し課金なし・トークン課金
- Batch API: grok-4.3 系は全トークン種別 20% 引き、レート制限を消費しない
- Priority Processing は 2 倍課金 (このユースケースでは不要)

### 実測コスト (重要)

**実際の請求はトークン+$5/1k calls の計算より 1 桁大きい。**

同一プロンプト・同一期間・`--max-turns 12` での実測 (ASR 調査、2026-08-27):

| モデル | 検索 | 入力 | 出力 | 計算上 | 実請求 | findings |
|--------|------|------|------|--------|--------|----------|
| grok-4.3 | 11 | 42k | 3.5k | $0.12 | **$0.97** | 4 |
| grok-4.3 | 9 | 41k | 3.6k | $0.11 | **$0.85** | 4 |
| grok-4.3 (`--max-turns 2`) | 4 | 13k | 1.4k | $0.04 | **$0.40** | 6 |
| grok-4.3 (追い質問) | 0 | 12k | 1.0k | $0.02 | **$0.18** | 2 (出典なし) |
| grok-4.5 | 20 | 191k | 11.7k | - | **$3.63** | **0** |
| grok-4.6 | 27 | 269k | 10.1k | - | **$10.14** | **0** |

差分の大半は x_search の課金である。1 回の検索が $0.005 ではなく $0.07〜0.08
相当になっている (公開価格表の $5/1,000 calls と一致しない)。原因は未特定だが、
**grok-4.3 の見積もりは 1 クエリ $1 前後**として扱う。

`usage.cost_in_usd_ticks / 1e9` が実請求額なので、毎回これを確認する。

### 上位モデルはターン予算を検索で使い切る

grok-4.5 / 4.6 は同じ `--max-turns` で grok-4.3 の 2〜3 倍検索し、**レポートを
書く前にターンが尽きて空の骨組みを返した** (`report` が中身のない仮置き文字列、
`findings` が空)。検索の質自体は高く、grok-4.3 が取りこぼした対象を見つけ
スレッドも辿っていたが、成果物は失われ、検索分だけが課金された。

このとき **API は `status: "completed"` を返し、`incomplete_details` も `null`**
だった (`GET /v1/responses/<id>` で確認)。サーバー側に失敗の痕跡がないため、
検出できるのは `sourcing.finding_count` だけである。

コストが線形に増えないのは、エージェントループの累積入力が膨らむため
(42k → 269k)。上位モデルを使うなら `--max-turns` を大きく取る必要があり、
$10 を超える前提で判断する。

## 課金の防御 (console.x.ai)

- プリペイドクレジット制。invoiced billing limit はデフォルト $0 のままにする
  (クレジットが尽きたらリクエストが拒否されるだけで請求が伸びない)
- オートトップアップは最低 $25 なので、小口なら手動購入
- Management API (`https://management-api.x.ai`) でキー作成時に `qps` / `qpm` /
  `tpm` を設定でき、暴走時の二重の防御になる

## 実行結果は毎回変わる (recall 非保証の実測)

同一プロンプト・同一期間で 2 回実行した結果、citations 約 58 件のうち**共通は
10 件だけ**だった (run1 のみ 48 件 / run2 のみ 47 件)。両方とも 9〜11 回検索し、
どちらも妥当な結果を返したが、見ているポストはほぼ別物である。

実際に run1 で見つかった日本語 OSS (実放送 CER 5.8%、目的に最も合致) は
run2 では 1 件も出てこなかった。**重要な調査では 1 回の実行を網羅と見なさない**。
取りこぼしが許容できない場合は、クエリを変えて複数回実行し結果を統合する。

## 実測で確定した事項 (grok-4.3、2026-08-27)

- **top-level `citations` は返らない**。出典はすべて `output_text` の
  `annotations` (`type: "url_citation"`) から回収する。実測では 58 件の
  annotations がすべて X ポスト URL だった
- **サブツール呼び出しは `custom_tool_call`** として現れる
  (`name` が `x_keyword_search` / `x_semantic_search`)。`x_search_call` 型は
  観測されていない
- **プロンプトに書いた演算子はそのまま `query` に載る**。実測クエリ:
  `ASR OR "speech recognition" ... since:2026-07-27 filter:links`、
  `"ASR model" ... url:arxiv.org OR url:huggingface.co`。日本語クエリに
  `min_faves:` を付けない指示も守られた
- **`include` が受理するのは `no_inline_citations` と
  `reasoning.encrypted_content` のみ**。`verbose_streaming` /
  `inline_citations` / `x_search_call_output` はいずれも HTTP 400
  (`Argument not supported`)。inline citations は既定で有効なため
  opt-in の値自体が存在しない
- **`usage.cost_in_usd_ticks` が返る**。実請求額は ticks / 1e9 で USD
  (実測 969,098,000 ticks = 約 $0.97)。`server_side_tool_usage` は返らず、
  代わりに `usage.server_side_tool_usage_details` に
  `{"x_search_calls": 11, ...}` が入る
- `--to` に指定した日付は `until:` に**そのまま渡らない**。`--to 2026-08-28`
  に対しモデルは `until:2026-08-27` を発行した。最終日は余裕を持たせる
- **`previous_response_id` の追い質問は citations を引き継がない**。実測で
  `search_call_count` 0 / `x_citation_count` 0、レスポンス中の `url_citation`
  annotations は 0 件。モデルは前回の知見を会話状態から答えるが、裏付けは
  失われるため全 findings が `unsourced_findings` に落ち、モデルが書いた URL も
  `dropped_unverified_urls` に隔離される。安い ($0.18) が出典付きの結果には
  ならない
- **HTTP 500 が実際に起きる**。grok-4.6 で
  `{"code":"internal","error":"Internal error during token generation"}` を観測。
  エージェントループを回しきった後に落ちうるため、検索ツールの課金は発生した上で
  出力が失われる。スクリプトは 5xx / 429 を既定 2 回まで指数バックオフで再試行する
  (`--retries`)

### 未検証

- `--effort` が調査の質に効くか。grok-4.3 は `none` / `low` / `high` の
  いずれも HTTP 200 で受理する (実測) が、検索の深さや findings の質が
  変わるかは未検証。既定のまま使うのが無難
- 追い質問で citations を引き継ぐ方法があるか (`store` の設定、`include` の
  指定など)。現状は下記のとおり引き継がれない

## 関連: hydrate (ポスト本文・メトリクスの取得)

citations の URL だけで足りるなら hydrate しないのが最大の節約。必要な場合は
X API (console.x.com、xAI とは別勘定) を使う:

- 公式 CLI: `npx -y @xdevplatform/xurl` (OAuth を CLI が処理)
- Post read は $0.005/件。24 時間 UTC ウィンドウ内の同一ポスト再取得は重複排除
  され課金 1 回のみ
- spending limit を請求サイクル単位で設定可能
