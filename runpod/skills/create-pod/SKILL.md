---
name: create-pod
description: Create RunPod GPU/CPU pods from runpod.toml. "create pod", "launch pod", "pod 立てて" などで起動。
metadata:
  author: pokutuna
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
- Use `--stop-after VALUE` only when the user requests an automatic stop. The value is passed through to the installed `runpodctl`.
- If the user requests Jupyter, use `--jupyter`. This adds `8888/http` and prints `https://<pod-id>-8888.proxy.runpod.net`; when `JUPYTER_PASSWORD` is in `[env]`, the printed URL also includes `?token=...`.
- RunPod Secret references are resolved only inside the Pod, not by this local script. If the user asks to connect to Jupyter and the printed URL contains `{{ RUNPOD_SECRET_... }}`, ask the user for the actual Jupyter password/token and replace the token part before returning the usable URL. Do not ask for it when the user only asks to create the Pod.

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
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_pod.py --stop-after 2h      # Auto-stop when requested
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_pod.py --jupyter           # Expose Jupyter and print URL
```

For low-stock GPUs, prefer `--ssh --retry` over wrapping the script in a shell loop. See `--help` for `--retry-interval` / `--retry-max`.

## CPU Pod

```bash
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_cpu_pod.py              # Create a CPU pod
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_cpu_pod.py --ssh        # Create and SSH connect
uv run --script ${CLAUDE_PLUGIN_ROOT}/skills/create-pod/scripts/create_cpu_pod.py --dry-run    # Show request body only
```

See `--help` for all options including `--cpu-flavor`, `--vcpu`, `--datacenter`.
