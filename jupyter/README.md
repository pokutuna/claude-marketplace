# jupyter

Connect a remote Jupyter Server (RunPod, GCP, self-hosted — cloud-agnostic) to Claude Code via [jupyter-mcp-server](https://github.com/datalayer/jupyter-mcp-server) (Datalayer, stdio).

GPU 付きリモートインスタンスの Jupyter Kernel を、手元のコーディングエージェントから使うためのプラグイン。

**既定は hybrid 構成**: notebook はプロジェクト内のローカルファイル、カーネルだけリモート (GPU) で動く。VS Code の "connect to remote Jupyter server" と同じ使い勝手で、pod を消しても notebook と実行結果は手元に残る。

## Skills

### connect-mcp

SSH コマンドまたは Jupyter URL を渡すと、リモートの Jupyter Server を MCP 経由で使えるようにする。

- **SSH コマンド**: `-L -N` でバックグラウンドトンネルを確立 (既定ローカルポート 48888)。token はリモートから自動取得を試みる
- **URL**: そのまま使う。`?token=xxx` 付き (RunPod の Connect リンク) なら token も抽出
- **ローカル doc server**: hybrid では `jupyter-collaboration` 入りの jupyter-server を uvx で自動起動し、プロジェクトディレクトリを公開する
- **`--remote-notebook`**: notebook もリモートに置く単一サーバー構成に切り替える
- **`--doc-root DIR`**: ローカル doc server が公開するディレクトリを指定 (既定はプロジェクトルート)

```
/jupyter:connect-mcp ssh -p 22078 root@203.0.113.10 -i ~/.ssh/runpod --token abc123
/jupyter:connect-mcp https://abcdef-8888.proxy.runpod.net/?token=abc123
/jupyter:connect-mcp <url> --remote-notebook  # notebook もリモートに置く
/jupyter:connect-mcp status      # 構成・doc server・疎通の確認
/jupyter:connect-mcp disconnect  # トンネルと doc server を停止 (.mcp.json は残る)
```

## How it works

Claude Code は `.mcp.json` をセッション開始時にしか読まないため、接続情報を直接書くと変更のたびにセッション再起動が必要になる。これを避けるため2層に分ける:

- **`.mcp.json`**: `~/.config/jupyter-mcp/wrapper.sh` を指す不変エントリのみ (token を含まないので git 管理も安全)
- **`~/.config/jupyter-mcp/current.env`**: URL/token の実体。wrapper が exec 時に読む

state ファイルの中身は上流の [configuration docs](https://github.com/datalayer/jupyter-mcp-server/blob/main/docs/docs/operations/configuration/index.mdx) の変数をそのまま使う:

| 構成 | 変数 | 上流での位置づけ |
|---|---|---|
| hybrid (既定) | `DOCUMENT_URL`/`DOCUMENT_TOKEN` (ローカル) + `CODE_SANDBOX_URL`/`CODE_SANDBOX_TOKEN` (リモート) | Advanced Configuration |
| `--remote-notebook` | `JUPYTER_URL`/`JUPYTER_TOKEN` | Simplified Configuration |

pod を切り替えたら skill を再実行するだけで state が置き換わり、**`/mcp` から reconnect すれば反映される** (セッション再起動は初回のエントリ追加時のみ)。

## Requirements

- `ssh`, `curl`, `jq`, `uv`
- リモート側で Jupyter Server が起動していること
- notebook 系ツール (`insert_execute_code_cell` 等) には `jupyter-collaboration` が必要。hybrid ではローカル doc server に uvx で入るので満たされる。`--remote-notebook` の場合はリモート側に必要 (RunPod の PyTorch テンプレには入っていない)
- hybrid には jupyter-mcp-server 1.5.2 以降が必要。wrapper は `@latest` なのでバージョンは固定していない。古い版が選ばれる場合は uv の `exclude-newer` 設定が効いている (skill の Known limitations 参照)

## Notes

- JupyterLab UI で MCP の notebook を開くと kernel 選択が出る (MCP_SERVER モードは Jupyter session を登録しないため)。新しい kernel を選ぶと状態の異なる2つ目が起動する。同じ状態を触るには "Use existing kernel" で稼働中の kernel を選ぶ
- hybrid ではカーネルがリモートなので、notebook 内の相対パスはリモート側の cwd を指す。データセットはリモートに置く
- ローカル doc server は `~/.config/jupyter-mcp/doc-server.{pid,token,url,root,log}` で管理。ポートは既定 48891 (使用中なら空きポート)
- uvx は隔離環境で動くため、ローカルの `.venv` に依存しない・汚さない。追加パッケージはリモート (pod) 側に入れる
- state ファイルは umask 077 (600 相当)、トンネルの pid/log は `${TMPDIR}/jupyter-mcp-tunnel/` に保存
