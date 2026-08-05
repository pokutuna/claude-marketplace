---
name: connect-mcp
description: Connect a remote Jupyter Server to this project via jupyter-mcp-server. Accepts an SSH command (auto tunnel) or a Jupyter URL + token; also handles status check and disconnect. "jupyter 繋いで", "connect jupyter", "jupyter mcp", "remote kernel", "jupyter status", "jupyter 切断" などで起動。
argument-hint: "<ssh command | jupyter url | status | disconnect> [--token TOKEN] [--remote-port N] [--local-port N]"
metadata:
  author: pokutuna
  compatibility: Requires ssh, curl, jq, uv (uvx)
allowed-tools:
  - Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/setup-tunnel.sh *)
  - Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/update-config.sh *)
  - Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/status.sh)
  - Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/stop-tunnel.sh *)
  - Bash(curl *)
  - Bash(ssh *)
  - Read
  - AskUserQuestion
---

# Jupyter MCP

リモートの Jupyter Server (RunPod / GCP / 自前サーバーなどクラウド非依存) を、Datalayer 製 [jupyter-mcp-server](https://github.com/datalayer/jupyter-mcp-server) 経由でプロジェクトに接続する。notebook もカーネルもリモート側で動く。

設定は2層: `.mcp.json` には wrapper (`~/.config/jupyter-mcp/wrapper.sh`) を指す不変エントリのみ、URL/token は state ファイル (`~/.config/jupyter-mcp/current.env`) に置き wrapper が起動時に読む。接続先の変更は state 更新 + **`/mcp` から reconnect** だけで反映され、セッション再起動が要るのは初回のエントリ追加時のみ。

<ARGUMENTS>
$ARGUMENTS
</ARGUMENTS>

## Operations

| 操作 | 入力 | 動作 |
|---|---|---|
| **connect** (既定) | SSH コマンド or URL | 下記 Connect 手順 |
| **status** | `status`, 「状態確認」 | `bash ${CLAUDE_PLUGIN_ROOT}/scripts/status.sh` を実行し要約 |
| **disconnect** | `disconnect`, 「切断」 | `bash ${CLAUDE_PLUGIN_ROOT}/scripts/stop-tunnel.sh [port\|all]` を実行 (既定 all)。`.mcp.json` は残る |

connect のオプション: `--token` / `--remote-port` (既定 8888) / `--local-port` (既定 48888)。

token の解決順: (1) 明示指定 → (2) URL の `?token=xxx` を抽出 (URL はオリジン部分だけ使う) → (3) SSH なら `ssh ... 'echo $JUPYTER_TOKEN'`、空なら `ssh ... 'jupyter server list'` から抽出 → (4) token なしで疎通確認し 401/403 ならユーザーに確認。

## Connect

### 1. Resolve remote URL

SSH コマンドの場合:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/setup-tunnel.sh "<ssh command>" [remote_port] [local_port]
```

`-N -L` と keep-alive を付与して切り離しバックグラウンド起動し、`JUPYTER_URL=` / `TUNNEL_PID=` / `LOG_FILE=` を出力する。同じ local port の既存トンネルは張り替え、他プロセス使用中なら空きポートにフォールバック。失敗時は stderr の SSH ログから原因を報告する (`BatchMode=yes` のためパスワード認証は不可、鍵認証を案内)。

URL の場合はそのまま使う。

### 2. Verify connectivity

```bash
curl -fsS --max-time 10 -H "Authorization: token <TOKEN>" "<REMOTE_URL>/api/kernels"
```

401/403 なら token を確認。接続不可ならリモートで Jupyter が起動しているか確認する。

### 3. Update config

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/update-config.sh "<REMOTE_URL>" "<TOKEN>" .mcp.json
```

token 省略時は `""`。最終行で案内を分岐:

- **`ENTRY_ADDED`** (初回): セッション再起動と MCP 接続の承認が必要
- **`ENTRY_UNCHANGED`**: **`/mcp` から jupyter-mcp-server を reconnect すれば反映される** (再起動不要)

## Known limitations

接続後に案内が必要になったら伝える:

- **notebook 系ツールには `jupyter-collaboration` が必要**: `use_notebook` + `insert_execute_code_cell` 等が `/api/collaboration/session/...` の 404 で失敗したら、リモートに拡張がない (RunPod の素のテンプレ等)。(a) notebook に保存されない `execute_code` で代替、(b) リモートに `pip install jupyter-collaboration` して Jupyter プロセスを再起動、のいずれかを案内する
- **JupyterLab UI で開くと kernel 選択が出る**: MCP_SERVER モードは notebook↔kernel の Jupyter session を登録しないため。ダイアログで新しい kernel を選ぶと2つ目が起動して状態が分かれる。MCP と同じ状態を触りたければ "Use existing kernel" で稼働中の kernel を選ぶよう案内する
- **ローカル notebook + リモートカーネル (hybrid) は標準では非対応**: jupyter-mcp-server の `use_notebook` が contents 系操作 (collaboration セッション・path チェック・create) を runtime 側サーバーに向ける上流バグのため。修正 fork ([pokutuna/jupyter-mcp-server](https://github.com/pokutuna/jupyter-mcp-server) の `fix-collab-session-document-url` ブランチ) で動作検証済み: wrapper の exec を `uvx --from git+https://github.com/pokutuna/jupyter-mcp-server@fix-collab-session-document-url jupyter-mcp-server` に変え、state ファイルに `DOCUMENT_URL`/`DOCUMENT_TOKEN` (ローカル doc server、要 jupyter-collaboration) + `CODE_SANDBOX_URL`/`CODE_SANDBOX_TOKEN` (リモート、main で RUNTIME_* から改名) を書く。upstream 修正が入れば通常構成で対応予定

## Examples

```
/jupyter:connect-mcp ssh -p 22078 root@203.0.113.10 -i ~/.ssh/runpod --token abc123
/jupyter:connect-mcp https://abcdef-8888.proxy.runpod.net/?token=abc123
/jupyter:connect-mcp status
/jupyter:connect-mcp disconnect
RunPod の pod を作り直したので jupyter 繋ぎ直して: ssh -p 22079 root@203.0.113.11 -i ~/.ssh/runpod
```
