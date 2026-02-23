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
  version: 0.2.0
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
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_pod.py                   # Create a GPU pod
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_pod.py --ssh             # Create and SSH connect
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_pod.py --dry-run         # Show command only
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_pod.py --gpu "RTX 5090"  # Override GPU type
```

## CPU Pod

```bash
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_cpu_pod.py              # Create a CPU pod
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_cpu_pod.py --ssh        # Create and SSH connect
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_cpu_pod.py --dry-run    # Show request body only
```

See `--help` for all options including `--cpu-flavor`, `--vcpu`, `--datacenter`.
