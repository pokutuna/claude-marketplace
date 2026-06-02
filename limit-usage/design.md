# limit-usage — 設計メモ

設定した使用率(rate limit utilization)に達したら、ツール実行を手前で止める Claude Code プラグイン。

## 目的・要件

- ユーザーが指定した使用量(例: 5h 枠を 80% 使ったら)で Claude の処理を止めたい
- hook で実現する
- **測定コストはゼロにする**(残量を測るために quota を消費しない)
- ユーザーが既にカスタム statusLine を使っている前提で、それを壊さない

## 調査で確定した事実(なぜこの設計か)

### quota / 利用状況の取得手段の比較

| 方式 | 測定コスト | 取れる情報 | 判定 |
|---|---|---|---|
| `GET /api/oauth/usage` 直叩き(`/usage` の実体) | ほぼゼロ | `utilization`% + `status` | ❌ OAuth トークン読み出しが必要。keychain のトークンは**失効していた**(実測 401)。`refreshOAuth: true` 相当のトークン更新を自前再実装する必要があり地雷 |
| `claude -p --output-format json` の `rate_limit_event` | ❌ **毎回 quota 消費** | `status`(allowed/allowed_warning/rejected)+ resetsAt + overage | ❌ 残量を測るために新規セッションを起動して推論を走らせる=本末転倒。2026/6/15 以降は Agent SDK の別枠消費の懸念もある |
| **statusLine stdin の `rate_limits`** | ⭕ **完全ゼロ**(本体の通常応答に相乗り) | `five_hour.used_percentage` / `seven_day.used_percentage`(0-100)+ `resets_at` | ✅ **採用**。追加リクエスト無し・トークン不要・リフレッシュ不要 |

### `rate_limits` / `rate_limit_event` の中身(Claude Code バイナリ v2.1.160 解析)

本体は API 応答ヘッダ `anthropic-ratelimit-unified-*` をパース(関数 `s97()`)して利用状況を保持している。ヘッダ群:

- `anthropic-ratelimit-unified-status` — `allowed` / `allowed_warning` / `rejected`
- `anthropic-ratelimit-unified-reset` — リセット epoch
- `anthropic-ratelimit-unified-fallback` — `available`
- `anthropic-ratelimit-unified-overage-status` / `-overage-reset` / `-overage-disabled-reason`
- `anthropic-ratelimit-unified-representative-claim` / `-upgrade-paths`

`status` の意味(本体の警告出し分けロジックより):

- `allowed` — 正常、表示なし
- `allowed_warning` — 上限が近い。`utilization >= 0.7`(70%以上)で warning 表示、70%未満は握りつぶし
- `rejected` — 上限到達、error 表示

`rateLimitType` enum: `five_hour | seven_day | seven_day_opus | seven_day_sonnet | overage`

`claude -p --output-format json` の実測サンプル:
```json
{"type":"rate_limit_event","rate_limit_info":{"status":"allowed","resetsAt":1780417800,
 "rateLimitType":"five_hour","overageStatus":"rejected","overageDisabledReason":"out_of_credits","isUsingOverage":false}}
```

### `rate_limits` を受け取れるのは statusLine だけ(重要な制約)

- **プラグインは statusLine を提供できない**(`plugin.json` の settings は `agent` と `subagentStatusLine` のみ対応。メインの `statusLine` 不可)
- **statusLine は単一・上書き式**。スコープ間でスタックされず、最も具体的なスコープが1個だけ勝つ
- **`rate_limits` を受け取る hook は statusLine のみ**。SessionStart / PreToolUse / PostToolUse / Notification / Stop いずれにも来ない
- `rate_limits` は **Claude.ai サブスク(Pro/Max/Team/Enterprise)のみ、セッション最初の API 応答以降**に出現。各 window は独立に欠落しうる

→ 結論: **ユーザーの既存 statusLine を wrapper で包み、stdin を state file に tee する**以外に、追加コストなしで `rate_limits` を取る方法は存在しない。

### 値の形式・単位(`~/.claude/statusline.ts` の実装で確認)

```ts
rate_limits?: {
  five_hour?: { used_percentage?: number; resets_at?: number };
  seven_day?: { used_percentage?: number; resets_at?: number };
};
```

- **`used_percentage`**: 単位は **パーセント(%)、0〜100 の数値**(小数あり、例 `23.5`)。**使用済み割合**(`80` = 80% 使った = 残り 20%)。公式ドキュメントも "from 0 to 100" と明記
- **`resets_at`**: **Unix epoch 秒**(時刻。パーセントではない)
- すべて optional。`rate_limits` 自体も含め欠落しうる(無料枠・初回 API 応答前)。参考実装も `input.rate_limits?.five_hour?.used_percentage` と全段 `?` でガードし、`fiveHourPct != null || sevenDayPct != null` で両方の欠落を確認している
- → `set 5h 80%` の `80` は **`used_percentage` の上限(%)**。判定は `used_percentage >= 80` で deny

### wrapper が stdin パススルーだけで成立する根拠(実装で確認済み)

参考実装(`~/.claude/statusline.ts`)の依存・出力を確認した結果、wrapper で完全透過できる:

| 依存/出力 | 実装での実際 | wrapper への影響 |
|---|---|---|
| 入力 | stdin のみ (`JSON.parse(await Bun.stdin.text())`) | stdin を tee して渡せば透過 |
| 引数 `argv` | 使っていない | wrapper が引数を消費してよい |
| 環境変数 | `HOME` のみ | wrapper は env を素通し |
| 外部コマンド | `ghq root` / `git -C` | wrapper は CWD/env を変えないので影響なし |
| 出力 | stdout に1行 `console.log` のみ | wrapper が stdout に触らなければそのまま表示される |
| 終了コード | 暗黙 0 | wrapper は元の exit code を返す |

→ wrapper は「stdin を `$(cat)` で吸う → rate state file に保存 → `printf '%s' "$input" | exec "$@"` で元コマンドへ stdin パススルー(stdout/stderr/exit code は触らない)」で成立。`ts` は `jq` の `now` で付与。

## アーキテクチャ

```
[Claude Code] --rate_limits(応答ヘッダ由来)--> statusLine stdin JSON
                                                    │
   settings.json: statusLine.command = wrapper.sh '<元コマンド>'
                                                    │
        wrapper.sh: stdin を state file に保存 → 元 statusLine に stdin パススルー
                                                    │
              ~/.local/state/limit-usage-rate.json (five_h%, seven_d%, resets, ts)
                                                    │
[PreToolUse] guard.sh check ── 閾値(gitconfig)と比較 ── 超過なら deny
                                                    │
[skill] /limit-usage ── 閾値設定 / setup(wrapper差し替えを対話的に案内) / teardown
```

## ディレクトリ構成

```
limit-usage/
├── .claude-plugin/plugin.json
├── hooks/hooks.json                    # PreToolUse(全ツール) → guard.sh check
├── bin/
│   ├── statusline-wrapper.sh           # stdin tee → 元コマンドへ pass-through
│   └── guard.sh                        # check / set / off / status / setup / teardown
├── skills/limit-usage/SKILL.md
├── design.md                           # このファイル
└── README.md
```

## コンポーネント仕様

### 1. statusline-wrapper.sh

- stdin を読み、`rate_limits.{five_hour,seven_day}.{used_percentage,resets_at}` + 取得時刻 `ts` を rate state file に保存
  - rate state file: `${XDG_STATE_HOME:-~/.local/state}/limit-usage-rate.json`
  - 例: `{"five_h":42,"seven_d":18,"five_reset":1780417800,"seven_reset":...,"ts":<epoch>}`
  - `rate_limits` 欠落時(無料枠・初回応答前)は書かない or null
- 第1引数の元コマンドに stdin をそのままパススルーして実行(`~` 展開・実行ビット対応)
- 元コマンドが無い(ユーザーが statusLine 未設定)場合は簡易表示 `5h: 42%` を自前で出力

### 2. guard.sh + gitconfig state

閾値・退避情報の state file(gitconfig 形式、`allow-until` 流):
`${XDG_STATE_HOME:-~/.local/state}/limit-usage.conf`

```ini
[global]
    five-hour = 80          ; 5h枠の使用率上限(%)。未設定=無効
    seven-day = 90          ; 7d枠の使用率上限(%)
    orig-statusline = "~/.claude/statusline.ts"   ; teardown 用に退避した元コマンド
[session "<CLAUDE_SESSION_ID>"]
    five-hour = 70          ; session 単位(既定の書き込み先・global より優先)
```

| キー | 意味 | 書き込み | 読み出し(check) |
|---|---|---|---|
| `five-hour` | 5h 枠の使用率上限(%) | `set 5h N`(既定 session / `--global` で global) | session.<id> → global → 無ければ無効 |
| `seven-day` | 7d 枠の使用率上限(%) | `set 7d N` 同上 | 同上 |
| `orig-statusline` | 退避した元 statusLine command | `setup` 時に global へ | `teardown` で復元 |

サブコマンド:

- **`check`**(PreToolUse hook):rate state file を読み、各 window で閾値を session→global フォールバックで取得。`used_percentage >= 閾値` なら deny。
  ```json
  {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny",
   "permissionDecisionReason":"5h usage 82% ≥ limit 80%. Resets at 14:30."}}
  ```
  - **fail-open**: 閾値未設定 / rate state file 無し / `rate_limits` 欠落 / ts が古すぎる → `exit 0`(素通り)
  - **自己デッドロック回避(重要)**: `tool_input.command` に `guard.sh` を含む呼び出しは閾値に関わらず常に素通り。guard 発動中もプラグイン自身の管理コマンド(`set` / `off` / `status` / `teardown`)は同じ Bash ツール経由なので、これを通さないと「閾値を下げて止めたのに下げ直す手段まで道連れ」でセッションが詰む。SKILL.md は guard.sh をフルパスで呼ぶため確実にマッチする(副作用: 文字列 `guard.sh` を含む任意コマンドも通るが、脱出ハッチがわずかに広いだけで実害なしと判断)
- **`set 5h 80%` / `set 7d 90%`**: 閾値を session(既定)or `--global` で global に書く
- **`off`**: セッション(or `--global`)の閾値を削除
- **`status`**: 現在の閾値設定 + rate state file の実残量を表示
- **`setup`**: settings.json の `statusLine.command` を wrapper に差し替え(対話的、下記)
- **`teardown`**: 退避した元コマンドに復元

切り替えロジック(セッション/全体):
- 書き込み先の選択(`--global` フラグ)で表現
- 読み出しは常に `session.<id>` → `global` の順でフォールバック
- 5h / 7d は独立した2キー(片方だけ設定も可)

### 3. setup の受け入れやすさ(skill で案内)

原則: **勝手に settings.json を書き換えない**。skill が「提案 → 差分提示 → 同意 → 適用」。

`/limit-usage setup` の流れ:
1. 現 `statusLine.command` を読む
2. before/after 差分を提示:
   ```
   現在:   "command": "~/.claude/statusline.ts"
   変更後: "command": ".../statusline-wrapper.sh '~/.claude/statusline.ts'"
   （表示はそのまま。利用率を裏でファイルに記録します。元コマンドは退避し teardown で復元可)
   ```
3. 同意を得てから settings.json を編集(AskUserQuestion)
4. statusLine 未設定のユーザーには「wrapper だけ入れますか?(簡易表示も出ます)」と案内
5. `teardown` でワンコマンド復元。アンインストール手順は README に明記
6. **冪等**: setup を再実行しても二重ラップしない(既に wrapper なら何もしない)

### 4. SKILL.md

`/limit-usage` の操作集約: `setup` / `set 5h 80%`(`--global`)/ `off` / `status` / `teardown`

## 設計上の注意点

- **測定コストゼロ**: `-p` を使わない。本体の通常応答に相乗りした `rate_limits` のみ
- **可逆性**: wrapper 差し替えは元コマンドを退避し teardown で完全復元。settings を壊さない
- **無料枠 / 初回応答前**: `rate_limits` が来ない → fail-open(素通り、警告ログのみ)
- **state file の鮮度**: statusLine は毎応答 + `refreshInterval` で更新。古すぎる ts なら素通り(安全側)
- **閾値の意味**: `used_percentage` の上限(`set 5h 80%` = 5h 枠を 80% 使ったら止める)
- **自己デッドロック回避**: guard 発動中も `set`/`off`/`status`/`teardown` は同じ Bash ツール経由 → これらをブロックすると復旧不能。`check` は `guard.sh` を含むコマンドを常に素通りさせて回避(動作確認で発覚した実バグ。`--plugin-dir` テストで `status` 自身がブロックされた)

## 参考にする既存プラグイン

- `allow-until`: gitconfig 形式 state file(`git config -f`)、session.<id> セクション、PreToolUse で `permissionDecision` を返す構造
- `pushover-notify`: hooks.json + bin + skills の構成、skill の toggle 案内

## 未確定 / 実装時に確認すること

- `rate_limit_event` に `utilization`(数値%)が乗るかは未確認(乗れば `-p` 不要のまま % 閾値を別ソースで補完する選択肢が生まれるが、現状は statusLine の `used_percentage` で足りる)
- `status`(allowed_warning/rejected)を補助シグナルとして使うか(現設計は used_percentage の閾値のみで判定。将来オプション)
- `docs/CHECKLIST.md` に沿って plugin.json / marketplace 登録を行う
