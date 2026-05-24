---
name: create-pod
description: |
  Create RunPod GPU or CPU pod instances from runpod.toml configuration.
  Use when user mentions "create pod", "launch pod", "runpod ssh",
  "pod 立てて", "pod 作成", "runpod 起動",
  "cpu pod", "CPU インスタンス", "GPU なしで pod".
  Do NOT use for managing existing pods (stop, remove, list).
metadata:
  author: pokutuna
  version: 0.4.0
allowed-tools:
  - "Bash(uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_pod.py:*)"
  - "Bash(uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_cpu_pod.py:*)"
---

# RunPod Pod Creation

Create RunPod pod instances from a `runpod.toml` configuration file.

## Important

- Pods incur costs while running. If creation or SSH fails, confirm with the user and stop/remove the pod
- CPU pods have a max container disk of **20GB**
- CPU pods: if `datacenter_id` in runpod.toml is not accepted by the REST API, use `--datacenter ""` to auto-place near the Network Volume
- **CPU pod defaults are tiny**: `cpu3c` + `--vcpu 2` = **4 GB RAM**. Large file downloads (e.g. `hf download` of multi-GB model shards) will SIGKILL (exit 137) due to cgroup memory limit. For HF model downloads, use `--cpu-flavor cpu3g --vcpu 4` (16 GB) or larger.
- **Use the non-deprecated runpodctl commands** (legacy forms still work but emit a deprecation warning):
  - Create pod: `runpodctl pod create` (NOT `runpodctl create pod`)
  - List pods: `runpodctl pod list` (NOT `runpodctl get pod`)
  - SSH info: `runpodctl ssh info <pod-id>` (NOT `runpodctl ssh connect <pod-id>`)
  - GPU types: `runpodctl gpu list` (NOT `runpodctl get gpus`)
- `create_pod.py` requires **runpodctl >= 2.1.7** (for `--network-volume-id` on the new `pod create` form)
- **Do NOT wrap `create_pod.py` in a shell `while` retry loop**. Use the built-in `--retry` flag — wrapping creates duplicate pods if your success/failure detection is wrong. The script also refuses to create when a pod with the same name is already running (override with `--allow-duplicate`).

## Prerequisites

- `runpodctl` CLI installed and configured (`~/.runpod/config.toml`)
- `runpod.toml` in the working directory (or specify with `-c`)

## Setup

If `runpod.toml` does not exist yet:

```bash
cp ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/templates/runpod.toml ./runpod.toml
mkdir -p scripts/runpod
cp ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/templates/init.sh ./scripts/runpod/init.sh
```

Edit `runpod.toml` with your settings. Register secrets at https://console.runpod.io/user/secrets and reference them as `{{ RUNPOD_SECRET_XXX }}` in `[env]`.

## Choosing the Script

| Request | Script | Reason |
|---|---|---|
| GPU pod (default) | `create_pod.py` | Wraps `runpodctl` CLI |
| CPU-only pod | `create_cpu_pod.py` | Uses REST API (`runpodctl` does not support CPU pods) |

Both scripts share the same `runpod.toml`. CPU script ignores GPU-specific fields (`gpu_type`, `gpu_count`).

## GPU Pod

```bash
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_pod.py                       # Create a GPU pod
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_pod.py --ssh                 # Create and SSH connect
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_pod.py --ssh --retry         # Wait for stock, then SSH in
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_pod.py --dry-run             # Show command only
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_pod.py --gpu "RTX 5090"      # Override GPU type
```

For low-stock GPUs, prefer `--ssh --retry` over wrapping the script in a shell loop. See `--help` for `--retry-interval` / `--retry-max`.

## CPU Pod

```bash
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_cpu_pod.py              # Create a CPU pod
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_cpu_pod.py --ssh        # Create and SSH connect
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_cpu_pod.py --dry-run    # Show request body only
```

See `--help` for all options including `--cpu-flavor`, `--vcpu`, `--datacenter`.
