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

### statusLine.command に焼くパスの問題と解決(`CLAUDE_PLUGIN_DATA` + SessionStart)

wrapper を settings.json の `statusLine.command` に書くとき、**どのパスを焼き込むか**が落とし穴。実機調査(クリーン環境 + 公式 docs)で確定した制約:

- `${CLAUDE_PLUGIN_ROOT}` は **statusLine 実行コンテキストでは展開されない**。statusLine に渡る env は `COLUMNS` / `LINES` / `FORCE_HYPERLINK` のみで、`CLAUDE_PLUGIN_ROOT` / `CLAUDE_PLUGIN_DATA` は来ない(hook context とは別)
- `${CLAUDE_PLUGIN_ROOT}` の実体は **バージョン入り cache パス** `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`。これを literal で焼くと **更新で壊れる**(旧バージョンは orphaned 後 7 日で削除)
- cache に `latest` / `current` 等のバージョン非依存 symlink は**存在しない**
- install/enable/update 時に発火する hook も**存在しない**(`Setup` は `--init-only` 専用で通常起動では発火せず使えない)

採用: **install 時に wrapper を `CLAUDE_PLUGIN_DATA`(バージョン更新を生き延びる永続ディレクトリ)へ 1 回コピーし、その安定パスを statusLine に焼く。**

- `CLAUDE_PLUGIN_DATA` = `~/.claude/plugins/data/<plugin-id>/`(`@`→`-`、例 `limit-usage-pokutuna-plugins`)。アンインストールまで永続
- `guard.sh install` が `$CLAUDE_PLUGIN_DATA/statusline-wrapper.sh` に wrapper をコピーし、`statusLine.command` にはそのパスを焼く。cache パスでないのでバージョン更新で壊れない
- **SessionStart 等での自動再コピーはしない**(wrapper の中身はほぼ変わらない。素朴さ優先で hook を増やさない)。plugin 更新で wrapper を変えたときだけ `/limit-usage-setup install` を再実行すれば最新がコピーし直される — README に明記
- env 伝播は層ごとに非対称(plugin-level hook = ROOT+DATA 両方 / skill frontmatter hook = ROOT のみ / Bash tool subprocess = どちらも無し)。install を処理する skill が `CLAUDE_PLUGIN_DATA` / `CLAUDE_PLUGIN_ROOT` を知るには **skill body の `${...}` 事前置換に頼る**(本体が置換。Bash tool subprocess の env には来ないので、skill body で env prefix として明示的に渡す)

### 編集対象 settings.json の特定 — Bash の env を信用しない(実機検証で確定)

install が書き換える settings.json をどう特定するか。user-scope は `CLAUDE_CONFIG_DIR` があれば `$CLAUDE_CONFIG_DIR/settings.json`、無ければ `~/.claude/settings.json`。ここに2つの落とし穴がある(クリーン環境テストで実際に踏んだ):

- **`CLAUDE_CONFIG_DIR` は `CLAUDE.md` の位置を動かさない**。`CLAUDE_CONFIG_DIR=/tmp/cc-clean` で起動しても CLAUDE.md は `~/.claude/CLAUDE.md` から読まれる(memory ディレクトリは `$CLAUDE_CONFIG_DIR` 側を指すのに非対称)。→ **コンテキストに出る CLAUDE.md のパスから設定ディレクトリを推測してはいけない**
- **Bash tool subprocess の `$CLAUDE_CONFIG_DIR` は profile に汚染される**。非対話シェルが `.zshenv` 等を読み直すため、profile に `export CLAUDE_CONFIG_DIR=~/.claude` があると、`CLAUDE_CONFIG_DIR=/tmp/cc-clean claude` で起動しても **Bash サブプロセス内では本番値に上書きされる**。skill が Bash で `${CLAUDE_CONFIG_DIR:-$HOME/.claude}` を評価すると本番 settings を掴み、クリーン環境テストのつもりで本番 dotfiles を編集しかける(= `CLAUDE_PLUGIN_DATA` で踏んだのと同じ「Bash subprocess の env は信用できない」問題)

**判断: 深追いしない(現状の歯止めで十分)。** 実害が出るのは「profile で `CLAUDE_CONFIG_DIR` を export しつつ別 config dir で起動して install する」というテスト特有の状況のみで、通常利用では起きない。万一誤ったファイルを掴んでも、install は (1) `statusLine` を実際に定義しているファイルを選ぶ、(2) symlink は `realpath` で実体解決、(3) 編集前に AskUserQuestion で対象パスを提示して同意を取る、の三重の歯止めでユーザーが気づいて止められる(実際テストで「`~/.claude/settings.json` は dotfiles symlink」を見て止められた)。`${CLAUDE_CONFIG_DIR}` を skill body の `${...}` 置換で渡せれば根治しうるが、展開される保証は未確認で、コストに見合わないと判断

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
[skill] /limit-usage-setup install ── wrapper を ${CLAUDE_PLUGIN_DATA}/ にコピー(安定パス確保・1回)
                                                    │
[Claude Code] --rate_limits(応答ヘッダ由来)--> statusLine stdin JSON
                                                    │
   settings.json: statusLine.command = ~/.claude/plugins/data/<id>/statusline-wrapper.sh '<元コマンド>'
                                                    │
        wrapper.sh: stdin を state file に保存 → 元 statusLine に stdin パススルー
                                                    │
              ~/.local/state/cc-limit-usage-rate.json ({rate_limits, ts})
                                                    │
[PreToolUse] guard.sh check ── 閾値(gitconfig)と比較 ── 超過なら deny
                                                    │
[skill] /limit-usage ── 閾値設定(set / off / status)
[skill] /limit-usage-setup ── install(wrapper差し替えを対話的に案内) / uninstall
```

## ディレクトリ構成

```
limit-usage/
├── .claude-plugin/plugin.json
├── hooks/hooks.json                    # PreToolUse(全ツール) → guard.sh check
├── bin/
│   ├── statusline-wrapper.sh           # stdin tee → 元コマンドへ pass-through
│   └── guard.sh                        # check / set / off / status / install / uninstall
│                                       # install が wrapper を CLAUDE_PLUGIN_DATA にコピー
├── skills/
│   ├── limit-usage/SKILL.md            # set / off / status(settings.json に触らない・Edit 権限なし)
│   └── limit-usage-setup/SKILL.md      # install / uninstall(settings.json を編集・Edit 権限あり)
├── design.md                           # このファイル
└── README.md
```

## コンポーネント仕様

### 1. statusline-wrapper.sh

- stdin を読み、`rate_limits` をそのまま + 取得時刻 `ts` を rate state file に保存(変換せず元構造を保持)
  - rate state file: `${XDG_STATE_HOME:-~/.local/state}/cc-limit-usage-rate.json`
  - 例: `{"rate_limits":{"five_hour":{"used_percentage":42,"resets_at":1780417800},"seven_day":{...}},"ts":<epoch>}`
  - `rate_limits` 欠落時(無料枠・初回応答前)は書かない(直前の snapshot を残す)
- 第1引数の元コマンドに stdin をそのままパススルーして実行。元コマンドが無ければ何も出力しない(元々空だった statusLine は空のまま尊重。Claude Code に組み込みデフォルト statusLine は無いので、自前で行を出すのは余計な押し付けになる)

### 2. guard.sh + gitconfig state

閾値・退避情報の state file(gitconfig 形式、`allow-until` 流):
`${XDG_STATE_HOME:-~/.local/state}/cc-limit-usage.conf`

```ini
[global]
    five-hour = 80          ; 5h枠の使用率上限(%)。未設定=無効
    seven-day = 90          ; 7d枠の使用率上限(%)
    orig-statusline = "~/.claude/statusline.ts"   ; uninstall 用に退避した元コマンド
[session "<CLAUDE_SESSION_ID>"]
    five-hour = 70          ; session 単位(既定の書き込み先・global より優先)
```

| キー | 意味 | 書き込み | 読み出し(check) |
|---|---|---|---|
| `five-hour` | 5h 枠の使用率上限(%) | `set 5h N`(既定 session / `--global` で global) | session.<id> → global → 無ければ無効 |
| `seven-day` | 7d 枠の使用率上限(%) | `set 7d N` 同上 | 同上 |
| `orig-statusline` | 退避した元 statusLine command | `install` 時に global へ | `uninstall` で復元 |

サブコマンド:

- **`check`**(PreToolUse hook):rate state file を読み、各 window で閾値を session→global フォールバックで取得。`used_percentage >= 閾値` なら deny。
  ```json
  {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny",
   "permissionDecisionReason":"5h usage 82% ≥ limit 80%. Resets at 14:30."}}
  ```
  - **fail-open**: 閾値未設定 / rate state file 無し / `rate_limits` 欠落 / ts が古すぎる → `exit 0`(素通り)
  - **自己デッドロック回避(重要)**: `tool_input.command` に `guard.sh` を含む呼び出しは閾値に関わらず常に素通り。guard 発動中もプラグイン自身の管理コマンド(`set` / `off` / `status` / `uninstall`)は同じ Bash ツール経由なので、これを通さないと「閾値を下げて止めたのに下げ直す手段まで道連れ」でセッションが詰む。SKILL.md は guard.sh をフルパスで呼ぶため確実にマッチする(副作用: 文字列 `guard.sh` を含む任意コマンドも通るが、脱出ハッチがわずかに広いだけで実害なしと判断)
- **`set 5h 80%` / `set 7d 90%`**: 閾値を session(既定)or `--global` で global に書く
- **`off`**: セッション(or `--global`)の閾値を削除
- **`status`**: 現在の閾値設定 + rate state file の実残量を表示
- **`install`**: settings.json の `statusLine.command` を wrapper に差し替え(対話的、下記)
- **`uninstall`**: 退避した元コマンドに復元

切り替えロジック(セッション/全体):
- 書き込み先の選択(`--global` フラグ)で表現
- 読み出しは常に `session.<id>` → `global` の順でフォールバック
- 5h / 7d は独立した2キー(片方だけ設定も可)

### 3. install の受け入れやすさ(limit-usage-setup skill で案内)

原則: **勝手に settings.json を書き換えない**。skill が「提案 → 差分提示 → 同意 → 適用」。settings.json を編集するのはこの `limit-usage-setup` skill だけで、日常の `limit-usage`(set/off/status)からは `Edit` 権限を外して最小権限にしている。

`/limit-usage-setup install` の流れ:
1. settings.json を**決め打ちせず解決する**。user-scope は `CLAUDE_CONFIG_DIR` があれば `$CLAUDE_CONFIG_DIR/settings.json`、無ければ `~/.claude/settings.json`(`CLAUDE_CONFIG_DIR` は `CLAUDE.md` の位置は動かさないので、コンテキストの CLAUDE.md パスから設定ディレクトリを推測しない — 環境変数を直接見る)。`statusLine` がプロジェクト `.claude/settings.json` 側にあることもあるので、実際に `statusLine` を定義しているファイルを選ぶ。**symlink なら `realpath` で実体を編集**(symlink を Edit でその場置換すると dotfiles 連携が壊れる。実機で踏んだ)。実体が dotfiles なら commit が要る旨を伝える
2. 現 `statusLine.command` を読む
3. `guard.sh install` が wrapper を `$CLAUDE_PLUGIN_DATA/statusline-wrapper.sh` にコピーし、before/after 差分を提示。**焼き込むのは `CLAUDE_PLUGIN_DATA` の安定パス**(バージョン非依存):
   ```
   現在:   "command": "~/.claude/statusline.ts"
   変更後: "command": "~/.claude/plugins/data/<id>/statusline-wrapper.sh '~/.claude/statusline.ts'"
   （表示はそのまま。利用率を裏でファイルに記録します。元コマンドは退避し uninstall で復元可)
   ```
4. 同意を得てから settings.json(実体)を編集(AskUserQuestion)。`type` / `padding` は保持
5. statusLine 未設定のユーザーには元コマンド無しで wrapper を噛ませる(表示は空のまま・計測のみ)
6. `uninstall` でワンコマンド復元。アンインストール手順は README に明記
7. **冪等**: install を再実行しても二重ラップしない(既に wrapper なら何もしない)
8. **更新**: plugin 更新で wrapper の中身を変えたら `/limit-usage-setup install` を再実行(安定パスは不変、コピーを上書きするだけ)

### 4. SKILL.md(2つに分割)

- **`limit-usage`**(日常): `set 5h 80%`(`--global`)/ `off` / `status`。`settings.json` に触らないので `allowed-tools` は guard.sh の Bash のみ(`Edit` なし)。未 install なら `/limit-usage-setup install` を案内。**出力は実行コマンドの結果を簡潔に述べるだけ**(set/off は 1 行確認、status は status 出力。現在値の長い内訳や他設定の案内・フォロー質問を並べない)
- **`limit-usage-setup`**(セットアップ): `install` / `uninstall`。`settings.json` を編集するため `allowed-tools` に `Edit(~/.claude/settings.json)` / `Edit(.claude/settings.json)` と、wrapper コピー先の `CLAUDE_PLUGIN_DATA` を渡す Bash を持つ
- どちらも frontmatter `argument-hint` で引数ヒントを表示

## 設計上の注意点

- **測定コストゼロ**: `-p` を使わない。本体の通常応答に相乗りした `rate_limits` のみ
- **可逆性**: wrapper 差し替えは元コマンドを退避し uninstall で完全復元。settings を壊さない
- **無料枠 / 初回応答前**: `rate_limits` が来ない → fail-open(素通り、警告ログのみ)
- **state file の鮮度**: statusLine は毎応答 + `refreshInterval` で更新。古すぎる ts なら素通り(安全側)
- **閾値の意味**: `used_percentage` の上限(`set 5h 80%` = 5h 枠を 80% 使ったら止める)
- **自己デッドロック回避**: guard 発動中も `set`/`off`/`status`/`uninstall` は同じ Bash ツール経由 → これらをブロックすると復旧不能。`check` は `guard.sh` を含むコマンドを常に素通りさせて回避(動作確認で発覚した実バグ。`--plugin-dir` テストで `status` 自身がブロックされた)
- **statusLine に焼くパス**: `${CLAUDE_PLUGIN_ROOT}` は statusLine で展開されず、cache パスはバージョン更新で壊れる。install が `CLAUDE_PLUGIN_DATA` の安定パスに wrapper を 1 回コピーし、それを焼く。詳細は「statusLine.command に焼くパスの問題と解決」節
- **settings.json の symlink**: dotfiles を symlink で管理しているユーザーでは、Edit が symlink を実ファイルに置換して連携を壊す。install/uninstall は `realpath` で実体を解決してから編集する(実機テストで発覚)
- **編集対象 settings.json の特定**: `~/.claude/settings.json` を決め打ちせず `CLAUDE_CONFIG_DIR` を考慮する。ただし Bash subprocess の `$CLAUDE_CONFIG_DIR` は profile に汚染されうるので過信しない。実害は限定的で深追いしない判断。詳細は「編集対象 settings.json の特定 — Bash の env を信用しない」節

## 参考にする既存プラグイン

- `allow-until`: gitconfig 形式 state file(`git config -f`)、session.<id> セクション、PreToolUse で `permissionDecision` を返す構造
- `pushover-notify`: hooks.json + bin + skills の構成、skill の toggle 案内

## 未確定 / 実装時に確認すること

- `rate_limit_event` に `utilization`(数値%)が乗るかは未確認(乗れば `-p` 不要のまま % 閾値を別ソースで補完する選択肢が生まれるが、現状は statusLine の `used_percentage` で足りる)
- `status`(allowed_warning/rejected)を補助シグナルとして使うか(現設計は used_percentage の閾値のみで判定。将来オプション)
- `docs/CHECKLIST.md` に沿って plugin.json / marketplace 登録を行う
