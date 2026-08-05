# jupyter

Connect a remote Jupyter Server (RunPod, GCP, self-hosted — cloud-agnostic) to Claude Code via [jupyter-mcp-server](https://github.com/datalayer/jupyter-mcp-server) (Datalayer, stdio).

GPU 付きリモートインスタンスの Jupyter Kernel を、手元のコーディングエージェントから使うためのプラグイン。notebook もカーネルもリモート側で動く。

## Skills

### connect-mcp

SSH コマンドまたは Jupyter URL を渡すと、リモートの Jupyter Server を MCP 経由で使えるようにする。

- **SSH コマンド**: `-L -N` でバックグラウンドトンネルを確立 (既定ローカルポート 48888)。token はリモートから自動取得を試みる
- **URL**: そのまま使う。`?token=xxx` 付き (RunPod の Connect リンク) なら token も抽出

```
/jupyter:connect-mcp ssh -p 22078 root@203.0.113.10 -i ~/.ssh/runpod --token abc123
/jupyter:connect-mcp https://abcdef-8888.proxy.runpod.net/?token=abc123
/jupyter:connect-mcp status      # トンネル・疎通の確認
/jupyter:connect-mcp disconnect  # トンネル停止 (.mcp.json は残る)
```

## How it works

Claude Code は `.mcp.json` をセッション開始時にしか読まないため、接続情報を直接書くと変更のたびにセッション再起動が必要になる。これを避けるため2層に分ける:

- **`.mcp.json`**: `~/.config/jupyter-mcp/wrapper.sh` を指す不変エントリのみ (token を含まないので git 管理も安全)
- **`~/.config/jupyter-mcp/current.env`**: `JUPYTER_URL` / `JUPYTER_TOKEN` の実体。wrapper が exec 時に読む

pod を切り替えたら skill を再実行するだけで state が置き換わり、**`/mcp` から reconnect すれば反映される** (セッション再起動は初回のエントリ追加時のみ)。

## Requirements

- `ssh`, `curl`, `jq`, `uv`
- リモート側で Jupyter Server が起動していること
- notebook 系ツール (`insert_execute_code_cell` 等) にはリモート側に `jupyter-collaboration` 拡張が必要 (RunPod の PyTorch テンプレには入っていない)。ない場合は notebook に保存されない `execute_code` のみ使える

## Notes

- JupyterLab UI で MCP の notebook を開くと kernel 選択が出る (MCP_SERVER モードは Jupyter session を登録しないため)。新しい kernel を選ぶと状態の異なる2つ目が起動する。同じ状態を触るには "Use existing kernel" で稼働中の kernel を選ぶ
- ローカル notebook + リモートカーネル (hybrid 構成) は上流バグ (`use_notebook` が contents 系操作を runtime 側に向ける) のため標準では非対応。修正 fork ([pokutuna/jupyter-mcp-server@fix-collab-session-document-url](https://github.com/pokutuna/jupyter-mcp-server/tree/fix-collab-session-document-url)) で動作検証済み、upstream 修正後に対応予定
- uvx は隔離環境で動くため、ローカルの `.venv` に依存しない・汚さない。追加パッケージはリモート (pod) 側に入れる
- state ファイルは umask 077 (600 相当)、トンネルの pid/log は `${TMPDIR}/jupyter-mcp-tunnel/` に保存
