---
name: create-cpu-pod
description: |
  Create RunPod CPU pod instances from runpod.toml via REST API.
  Use when user mentions "cpu pod", "cpu instance", "CPU インスタンス",
  "GPU なしで pod", "データコピー用 pod".
metadata:
  author: pokutuna
  version: 0.1.0
  compatibility: RunPod API (requires ~/.runpod/config.toml or RUNPOD_API_KEY)
allowed-tools: "Bash(uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-cpu-pod/scripts/create_cpu_pod.py:*)"
---

# RunPod CPU Pod Creation

Create RunPod CPU-only pod instances from a `runpod.toml` configuration file.
Uses the RunPod REST API directly since `runpodctl` CLI does not support CPU pods.

Reuses `[volume]`, `[init]`, `[env]` sections from the same `runpod.toml` used by GPU pods.
GPU-specific fields (`gpu_type`, `gpu_count`) are ignored.

## Prerequisites

- `runpodctl` CLI installed and configured (`~/.runpod/config.toml`) for API key and SSH
- `uv` for running the script

## Usage

```bash
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-cpu-pod/scripts/create_cpu_pod.py                        # Create a CPU pod
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-cpu-pod/scripts/create_cpu_pod.py --ssh                  # Create and SSH connect
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-cpu-pod/scripts/create_cpu_pod.py --dry-run              # Show request body only
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-cpu-pod/scripts/create_cpu_pod.py -c other.toml          # Use a different config
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-cpu-pod/scripts/create_cpu_pod.py --cpu-flavor cpu5g     # Override CPU flavor
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-cpu-pod/scripts/create_cpu_pod.py --vcpu 4               # Override vCPU count
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-cpu-pod/scripts/create_cpu_pod.py --datacenter ""        # Skip datacenter from toml
```

See `--help` for all options.

## CPU Flavors

| ID | Type |
|---|---|
| `cpu3c` | CPU3 Compute Optimized (default) |
| `cpu3g` | CPU3 General Purpose |
| `cpu3m` | CPU3 Memory Optimized |
| `cpu5c` | CPU5 Compute Optimized |
| `cpu5g` | CPU5 General Purpose |
| `cpu5m` | CPU5 Memory Optimized |

## Important

- CPU pods have a **max container disk of 20GB** (API returns error if exceeded)
- `runpod.toml` の `datacenter_id` が REST API の許可リストにない場合がある。`--datacenter ""` で省略すると Network Volume のあるデータセンターに自動配置される
- Pods incur costs while running. If creation fails, confirm with the user and remove the pod (`runpodctl remove pod <pod_id>`)
