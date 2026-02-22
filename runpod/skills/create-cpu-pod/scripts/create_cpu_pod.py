#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""
RunPod CPU Pod Creation Script

Reads config from runpod.toml (same format as GPU pod) and creates a CPU pod
via the RunPod REST API, since runpodctl CLI does not support CPU pods.

Reuses [volume], [init], [env] sections from runpod.toml.
GPU-specific fields (gpu_type, gpu_count) are ignored.

Usage:
  uv run --script create_cpu_pod.py                 # Create a CPU pod
  uv run --script create_cpu_pod.py --ssh            # Create and SSH connect
  uv run --script create_cpu_pod.py --dry-run        # Show request body only
  uv run --script create_cpu_pod.py -c other.toml    # Use a different config
"""

from __future__ import annotations

import argparse
import json
import os
import shlex
import shutil
import subprocess
import sys
import time
import tomllib
import urllib.request
from pathlib import Path

CPU_DEFAULTS = {
    "cpu_flavor": "cpu3c",
    "vcpu_count": 2,
    "container_disk_size": 20,
    "image": "runpod/base:1.0.2-ubuntu2404",
    "ports": ["22/tcp"],
    "secure_cloud": True,
}


def find_config(config_path: str | None) -> Path:
    if config_path:
        p = Path(config_path)
        if not p.exists():
            print(f"Error: Config file not found: {p}", file=sys.stderr)
            sys.exit(1)
        return p

    p = Path.cwd() / "runpod.toml"
    if p.exists():
        return p

    print("Error: runpod.toml not found in current directory", file=sys.stderr)
    print("Use --config to specify the path", file=sys.stderr)
    sys.exit(1)


def load_config(config_path: Path) -> dict:
    with open(config_path, "rb") as f:
        config = tomllib.load(f)

    config.setdefault("pod", {})
    config.setdefault("volume", {})
    config.setdefault("init", {})
    config.setdefault("env", {})

    return config


def get_api_key() -> str:
    key = os.environ.get("RUNPOD_API_KEY")
    if key:
        return key

    config_path = Path.home() / ".runpod" / "config.toml"
    if config_path.exists():
        with open(config_path, "rb") as f:
            config = tomllib.load(f)
        key = config.get("apikey") or config.get("default", {}).get("api_key")
        if key:
            return key

    print(
        "Error: RUNPOD_API_KEY not set and not found in ~/.runpod/config.toml",
        file=sys.stderr,
    )
    sys.exit(1)


def build_request_body(config: dict, args: argparse.Namespace) -> dict:
    pod = config["pod"]
    volume = config.get("volume", {})
    env_config = config.get("env", {})

    name = args.name or pod.get("name", "cpu-pod")
    image = args.image or pod.get("image", CPU_DEFAULTS["image"])
    cpu_flavor = args.cpu_flavor or pod.get("cpu_flavor", CPU_DEFAULTS["cpu_flavor"])
    vcpu_count = args.vcpu or pod.get("vcpu_count", CPU_DEFAULTS["vcpu_count"])
    # CPU pods have a max container disk of 20GB (API rejects larger values)
    container_disk = min(
        pod.get("container_disk_size", CPU_DEFAULTS["container_disk_size"]),
        20,
    )
    ports = pod.get("ports", CPU_DEFAULTS["ports"])
    secure_cloud = pod.get("secure_cloud", CPU_DEFAULTS["secure_cloud"])

    body: dict = {
        "computeType": "CPU",
        "cpuFlavorIds": [cpu_flavor],
        "cpuFlavorPriority": "availability",
        "name": name,
        "imageName": image,
        "containerDiskInGb": container_disk,
        "vcpuCount": vcpu_count,
        "ports": ports,
        "cloudType": "SECURE" if secure_cloud else "COMMUNITY",
        "supportPublicIp": True,
    }

    datacenter_id = (
        args.datacenter if args.datacenter is not None else pod.get("datacenter_id")
    )
    if datacenter_id:
        body["dataCenterIds"] = [datacenter_id]
        body["dataCenterPriority"] = "custom"

    network_volume_id = volume.get("network_volume_id")
    if network_volume_id:
        body["networkVolumeId"] = network_volume_id
        body["volumeMountPath"] = volume.get("volume_path", "/workspace")
    else:
        volume_size = volume.get("volume_size", 0)
        if volume_size > 0:
            body["volumeInGb"] = volume_size
            body["volumeMountPath"] = volume.get("volume_path", "/workspace")

    if env_config:
        env_dict = {}
        for key, value in env_config.items():
            env_dict[key] = str(value)
        quota_gb = volume.get("quota_gb")
        if quota_gb is not None:
            env_dict.setdefault("WORKSPACE_QUOTA_GB", str(quota_gb))
        body["env"] = env_dict

    return body


def create_pod_api(body: dict, api_key: str) -> dict:
    url = "https://rest.runpod.io/v1/pods"
    data = json.dumps(body).encode()
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        error_body = e.read().decode()
        print(f"Error: API returned {e.code}", file=sys.stderr)
        print(error_body, file=sys.stderr)
        sys.exit(1)


def print_pod_summary(body: dict) -> None:
    print("Creating RunPod CPU instance...")
    print(f"  Name: {body['name']}")
    print(f"  CPU Flavor: {body['cpuFlavorIds'][0]}")
    print(f"  vCPUs: {body['vcpuCount']}")
    print(f"  Image: {body['imageName']}")
    print(f"  Container Disk: {body['containerDiskInGb']}GB")
    if body.get("dataCenterIds"):
        print(f"  Datacenter: {body['dataCenterIds'][0]}")
    if body.get("networkVolumeId"):
        print(
            f"  Network Volume: {body['networkVolumeId']} -> {body.get('volumeMountPath', '/workspace')}"
        )
    print()


def wait_for_ssh(pod_id: str, timeout: int = 300, interval: int = 5) -> str | None:
    if not shutil.which("runpodctl"):
        print(
            "Warning: runpodctl not found, cannot auto-connect SSH",
            file=sys.stderr,
        )
        return None

    start = time.time()
    while time.time() - start < timeout:
        result = subprocess.run(
            ["runpodctl", "ssh", "connect", pod_id],
            capture_output=True,
            text=True,
        )
        output = result.stdout + result.stderr
        if "ssh " in output:
            print()
            return output

        elapsed = int(time.time() - start)
        print(f"  Not ready yet... ({elapsed}s/{timeout}s)", file=sys.stderr)
        time.sleep(interval)

    return None


def parse_ssh_command(ssh_info: str) -> list[str]:
    for line in ssh_info.splitlines():
        line = line.strip()
        if line.startswith("ssh "):
            return shlex.split(line)

    print(
        f"Error: Could not parse SSH command from output:\n{ssh_info}",
        file=sys.stderr,
    )
    sys.exit(1)


def build_remote_command(config: dict, config_dir: Path) -> str | None:
    init_config = config.get("init", {})
    script_path = init_config.get("script")
    commands = init_config.get("commands", [])

    if not script_path and not commands:
        return None

    parts: list[str] = []
    parts.append("source /etc/rp_environment 2>/dev/null")

    if script_path:
        full_path = config_dir / script_path
        if not full_path.exists():
            print(f"Error: Init script not found: {full_path}", file=sys.stderr)
            sys.exit(1)
        escaped = shlex.quote(full_path.read_text())
        parts.append(f"bash -c {escaped}")

    for cmd in commands:
        parts.append(cmd)

    parts.append("exec bash -i")
    return " && ".join(parts)


def build_ssh_args(ssh_cmd: list[str], remote_command: str | None) -> list[str]:
    if not remote_command:
        return ssh_cmd
    return [*ssh_cmd, "-t", remote_command]


def ssh_in_tmux_window(ssh_cmd: list[str], remote_command: str | None) -> None:
    args = build_ssh_args(ssh_cmd, remote_command)
    result = subprocess.run(
        ["tmux", "new-window", ";", "send-keys", shlex.join(args), "Enter"]
    )
    if result.returncode != 0:
        print(
            "Warning: Failed to open tmux window. Falling back to direct SSH.",
            file=sys.stderr,
        )
        os.execvp(args[0], args)
    print("Opened new tmux window with SSH connection.")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Create a RunPod CPU pod from runpod.toml"
    )
    parser.add_argument(
        "--config",
        "-c",
        metavar="PATH",
        help="Path to runpod.toml (default: ./runpod.toml)",
    )
    parser.add_argument(
        "--ssh", action="store_true", help="Wait for pod and connect via SSH"
    )
    parser.add_argument("--name", help="Override pod name")
    parser.add_argument("--image", help="Override container image")
    parser.add_argument("--datacenter", help="Override datacenter ID")
    parser.add_argument(
        "--cpu-flavor",
        help="CPU flavor ID (default: cpu3c)",
        choices=["cpu3c", "cpu3g", "cpu3m", "cpu5c", "cpu5g", "cpu5m"],
    )
    parser.add_argument("--vcpu", type=int, help="Number of vCPUs (default: 2)")
    parser.add_argument(
        "--dry-run", action="store_true", help="Print request body without executing"
    )
    args = parser.parse_args()

    api_key = get_api_key()
    config_path = find_config(args.config)
    config = load_config(config_path)
    config_dir = config_path.parent

    body = build_request_body(config, args)

    if args.dry_run:
        print(json.dumps(body, indent=2))
        return

    print_pod_summary(body)
    result = create_pod_api(body, api_key)

    pod_id = result.get("id")
    if not pod_id:
        print("Failed to create pod or parse pod ID.", file=sys.stderr)
        print(json.dumps(result, indent=2), file=sys.stderr)
        sys.exit(1)

    cost = result.get("costPerHr", "?")
    print(f'Pod created: "{pod_id}" for ${cost} / hr')
    print("Check status: runpodctl get pod")

    if not args.ssh:
        return

    print()
    print("Waiting for SSH to become available...")
    ssh_info = wait_for_ssh(pod_id)

    if not ssh_info:
        print(f"Timed out. Try: runpodctl ssh connect {pod_id}", file=sys.stderr)
        sys.exit(1)

    ssh_cmd = parse_ssh_command(ssh_info)
    remote_command = build_remote_command(config, config_dir)
    use_tmux = config.get("init", {}).get("tmux_window", False)

    if remote_command:
        reconnect_args = build_ssh_args(ssh_cmd, remote_command)
        print(f"Reconnect: {shlex.join(reconnect_args)}")
        print()

    if use_tmux:
        ssh_in_tmux_window(ssh_cmd, remote_command)
    else:
        exec_args = build_ssh_args(ssh_cmd, remote_command)
        print(f"Connecting: {shlex.join(exec_args)}")
        os.execvp(exec_args[0], exec_args)


if __name__ == "__main__":
    main()
