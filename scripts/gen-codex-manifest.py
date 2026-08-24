#!/usr/bin/env python3
"""Generate .codex-plugin/plugin.json from .claude-plugin/plugin.json.

Codex reads `.codex-plugin/plugin.json`; Claude Code reads `.claude-plugin/plugin.json`.
Both clients share `skills/`, so the skills themselves need no changes: Codex lists each
SKILL.md by absolute path in its prompt, so `${CLAUDE_PLUGIN_ROOT}` in skill bodies gets
resolved by the model to the directory it read the skill from.

Fields Codex requires that Claude's manifest has no equivalent for (interface.*) are read
from a per-plugin block in codex-interface.json, so regenerating never loses hand-written
presentation metadata.
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
INTERFACE_DB = ROOT / "scripts" / "codex-interface.json"
CARRY = ("name", "version", "description", "author", "homepage", "repository", "license", "keywords")


def build(plugin: str, interfaces: dict) -> dict:
    claude = json.loads((ROOT / plugin / ".claude-plugin" / "plugin.json").read_text())
    if plugin not in interfaces:
        raise SystemExit(f"{plugin}: no interface block in {INTERFACE_DB.name}")

    out = {k: claude[k] for k in CARRY if k in claude}
    out.setdefault("version", "0.1.0")
    out.setdefault("author", {"name": "pokutuna"})
    out["homepage"] = f"https://github.com/pokutuna/claude-plugins/tree/main/{plugin}"
    out["repository"] = "https://github.com/pokutuna/claude-plugins"
    out["license"] = "MIT"
    out["skills"] = "./skills/"
    out["interface"] = interfaces[plugin]
    return out


def main(argv: list[str]) -> int:
    interfaces = json.loads(INTERFACE_DB.read_text())
    targets = argv or sorted(interfaces)
    for plugin in targets:
        dest = ROOT / plugin / ".codex-plugin"
        dest.mkdir(exist_ok=True)
        (dest / "plugin.json").write_text(json.dumps(build(plugin, interfaces), indent=2, ensure_ascii=False) + "\n")
        print(f"wrote {plugin}/.codex-plugin/plugin.json")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
