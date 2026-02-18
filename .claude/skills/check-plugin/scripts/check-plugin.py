#!/usr/bin/env -S uv run --script
#
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
#
"""プラグインの構成をチェックするバリデーションスクリプト。

Usage:
    check-plugin.py <repo-root> [<plugin-name>]

plugin-name を省略した場合は marketplace.json に登録された全プラグインをチェックする。
"""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Callable

KEBAB_CASE = re.compile(r"^[a-z][a-z0-9]*(-[a-z0-9]+)*$")
SEMVER = re.compile(r"^\d+\.\d+\.\d+")


class Status(Enum):
    OK = "OK"
    NG = "NG"
    WARN = "WARN"


@dataclass
class Result:
    status: Status
    message: str
    fix: str = ""


def ok(msg: str) -> Result:
    return Result(Status.OK, msg)


def ng(msg: str, fix: str = "") -> Result:
    return Result(Status.NG, msg, fix)


def warn(msg: str) -> Result:
    return Result(Status.WARN, msg)


@dataclass
class PluginContext:
    """ルール関数に渡されるコンテキスト。"""

    repo_root: Path
    plugin_name: str
    plugin_dir: Path
    plugin_json: dict | None = None  # パース済み plugin.json (なければ None)
    marketplace_plugins: list[dict] = field(default_factory=list)
    skills: list[SkillInfo] = field(default_factory=list)


@dataclass
class SkillInfo:
    name: str
    dir: Path
    skill_md_path: Path
    content: str  # SKILL.md の内容
    frontmatter: str | None  # frontmatter 部分 (パースできなければ None)


# Rule = context を受け取り Result のリストを返す関数
Rule = Callable[[PluginContext], list[Result]]


def rule_plugin_name_kebab(ctx: PluginContext) -> list[Result]:
    """プラグイン名が kebab-case であること。"""
    if KEBAB_CASE.match(ctx.plugin_name):
        return [ok(f"プラグイン名 '{ctx.plugin_name}' は kebab-case")]
    return [ng(f"プラグイン名 '{ctx.plugin_name}' が kebab-case でない")]


def rule_plugin_json_exists(ctx: PluginContext) -> list[Result]:
    """plugin.json が存在すること。"""
    path = ctx.plugin_dir / ".claude-plugin" / "plugin.json"
    if path.exists():
        return [ok("plugin.json が存在する")]
    return [ng(f"{path.relative_to(ctx.repo_root)} が存在しない")]


def rule_plugin_json_name(ctx: PluginContext) -> list[Result]:
    """plugin.json の name がディレクトリ名と一致すること。"""
    if ctx.plugin_json is None:
        return []
    pj_name = ctx.plugin_json.get("name", "")
    if not pj_name:
        return [ng("plugin.json に name がない")]
    results = [ok("plugin.json に name がある")]
    if pj_name == ctx.plugin_name:
        results.append(ok("plugin.json の name がディレクトリ名と一致する"))
    else:
        results.append(
            ng(
                f"plugin.json の name '{pj_name}' がディレクトリ名 '{ctx.plugin_name}' と一致しない",
                f"plugin.json の name を '{ctx.plugin_name}' に変更してください",
            )
        )
    return results


def rule_plugin_json_version(ctx: PluginContext) -> list[Result]:
    """plugin.json の version がセマンティックバージョニング形式であること。"""
    if ctx.plugin_json is None:
        return []
    version = ctx.plugin_json.get("version", "")
    if not version:
        return [ng("plugin.json に version がない")]
    if SEMVER.match(version):
        return [ok(f"version '{version}' はセマンティックバージョニング形式")]
    return [ng(f"version '{version}' がセマンティックバージョニング形式でない")]


def rule_plugin_json_description(ctx: PluginContext) -> list[Result]:
    """plugin.json に description があること。"""
    if ctx.plugin_json is None:
        return []
    if ctx.plugin_json.get("description"):
        return [ok("plugin.json に description がある")]
    return [ng("plugin.json の description が空", "description を記述してください")]


def rule_plugin_json_author(ctx: PluginContext) -> list[Result]:
    """plugin.json に author があること。"""
    if ctx.plugin_json is None:
        return []
    if ctx.plugin_json.get("author"):
        return [ok("plugin.json に author がある")]
    return [ng("plugin.json に author がない")]


def rule_plugin_json_keywords(ctx: PluginContext) -> list[Result]:
    """plugin.json に keywords があること。"""
    if ctx.plugin_json is None:
        return []
    if "keywords" in ctx.plugin_json:
        return [ok("plugin.json に keywords がある")]
    return [warn("plugin.json に keywords がない")]


def rule_readme_exists(ctx: PluginContext) -> list[Result]:
    """プラグインに README.md があること (推奨)。"""
    if (ctx.plugin_dir / "README.md").exists():
        return [ok("README.md が存在する")]
    return [warn("README.md がない (推奨)")]


def rule_marketplace_entry(ctx: PluginContext) -> list[Result]:
    """marketplace.json にエントリがあり、整合性があること。"""
    mp_entry = next(
        (p for p in ctx.marketplace_plugins if p.get("name") == ctx.plugin_name),
        None,
    )
    if mp_entry is None:
        return [
            ng(
                "marketplace.json に登録されていない",
                "marketplace.json の plugins 配列にエントリを追加してください",
            )
        ]
    results = [ok("marketplace.json に登録されている")]
    if mp_entry.get("description"):
        results.append(ok("marketplace.json の description が空でない"))
    else:
        results.append(ng("marketplace.json の description が空"))
    source = mp_entry.get("source", "")
    expected = f"./{ctx.plugin_name}"
    if source == expected:
        results.append(ok(f"marketplace.json の source が正しい ({expected})"))
    else:
        results.append(
            ng(
                f"marketplace.json の source '{source}' が期待値 '{expected}' と異なる",
                f"source を '{expected}' に変更してください",
            )
        )
    return results


def rule_root_readme_entry(ctx: PluginContext) -> list[Result]:
    """ルート README のプラグイン一覧にエントリがあること。"""
    root_readme = ctx.repo_root / "README.md"
    if not root_readme.exists():
        return []
    text = root_readme.read_text()
    if f"[{ctx.plugin_name}]" in text or f"/{ctx.plugin_name}/" in text:
        return [ok("ルート README のプラグイン一覧にエントリがある")]
    return [
        ng(
            "ルート README のプラグイン一覧にエントリがない",
            "README.md のプラグイン一覧テーブルにエントリを追加してください",
        )
    ]


def rule_codeowners_entry(ctx: PluginContext) -> list[Result]:
    """CODEOWNERS にエントリがあること。"""
    codeowners = ctx.repo_root / ".github" / "CODEOWNERS"
    if not codeowners.exists():
        return []
    if f"/{ctx.plugin_name}/" in codeowners.read_text():
        return [ok("CODEOWNERS にエントリがある")]
    return [warn("CODEOWNERS にエントリがない")]


def rule_skill_md_exists(ctx: PluginContext) -> list[Result]:
    """各スキルに SKILL.md が存在すること。"""
    results: list[Result] = []
    for skill in ctx.skills:
        if skill.skill_md_path.exists():
            results.append(ok(f"skills/{skill.name}/SKILL.md が存在する"))
        else:
            results.append(ng(f"skills/{skill.name}/SKILL.md が存在しない"))
    return results


def rule_skill_frontmatter(ctx: PluginContext) -> list[Result]:
    """各スキルの frontmatter に name と description があること。"""
    results: list[Result] = []
    for skill in ctx.skills:
        if skill.frontmatter is None:
            results.append(ng(f"skills/{skill.name}: YAML frontmatter がない"))
            continue
        if "name:" in skill.frontmatter:
            results.append(ok(f"skills/{skill.name}: frontmatter に name がある"))
        else:
            results.append(ng(f"skills/{skill.name}: frontmatter に name がない"))
        if "description:" in skill.frontmatter:
            results.append(
                ok(f"skills/{skill.name}: frontmatter に description がある")
            )
        else:
            results.append(
                ng(f"skills/{skill.name}: frontmatter に description がない")
            )
    return results


def rule_skill_name_kebab(ctx: PluginContext) -> list[Result]:
    """各スキル名が kebab-case であること。"""
    results: list[Result] = []
    for skill in ctx.skills:
        if KEBAB_CASE.match(skill.name):
            results.append(ok(f"スキル名 '{skill.name}' は kebab-case"))
        else:
            results.append(ng(f"スキル名 '{skill.name}' が kebab-case でない"))
    return results


RULES: list[Rule] = [
    rule_plugin_name_kebab,
    rule_plugin_json_exists,
    rule_plugin_json_name,
    rule_plugin_json_version,
    rule_plugin_json_description,
    rule_plugin_json_author,
    rule_plugin_json_keywords,
    rule_readme_exists,
    rule_marketplace_entry,
    rule_root_readme_entry,
    rule_codeowners_entry,
    rule_skill_md_exists,
    rule_skill_frontmatter,
    rule_skill_name_kebab,
]


def build_context(
    repo_root: Path, plugin_name: str, marketplace_plugins: list[dict]
) -> PluginContext:
    plugin_dir = repo_root / plugin_name

    # plugin.json
    plugin_json = None
    plugin_json_path = plugin_dir / ".claude-plugin" / "plugin.json"
    if plugin_json_path.exists():
        try:
            plugin_json = json.loads(plugin_json_path.read_text())
        except json.JSONDecodeError:
            pass

    # skills
    skills: list[SkillInfo] = []
    skills_dir = plugin_dir / "skills"
    if skills_dir.exists():
        for skill_dir in sorted(skills_dir.iterdir()):
            if not skill_dir.is_dir():
                continue
            skill_md = skill_dir / "SKILL.md"
            content = ""
            frontmatter = None
            if skill_md.exists():
                content = skill_md.read_text()
                if content.startswith("---"):
                    parts = content.split("---", 2)
                    if len(parts) >= 3:
                        frontmatter = parts[1]
            skills.append(
                SkillInfo(
                    name=skill_dir.name,
                    dir=skill_dir,
                    skill_md_path=skill_md,
                    content=content,
                    frontmatter=frontmatter,
                )
            )

    return PluginContext(
        repo_root=repo_root,
        plugin_dir=plugin_dir,
        plugin_name=plugin_name,
        plugin_json=plugin_json,
        marketplace_plugins=marketplace_plugins,
        skills=skills,
    )


def check_plugin(ctx: PluginContext) -> list[Result]:
    results: list[Result] = []
    for rule in RULES:
        results.extend(rule(ctx))
    return results


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: check-plugin.py <repo-root> [<plugin-name>]", file=sys.stderr)
        sys.exit(1)

    repo_root = Path(sys.argv[1]).resolve()
    target_plugin = sys.argv[2] if len(sys.argv) >= 3 else None

    # marketplace.json を読む
    mp_path = repo_root / ".claude-plugin" / "marketplace.json"
    if not mp_path.exists():
        print(f"ERROR: {mp_path} が見つかりません", file=sys.stderr)
        sys.exit(1)

    mp_data = json.loads(mp_path.read_text())
    mp_plugins = mp_data.get("plugins", [])

    # チェック対象の決定
    if target_plugin:
        plugin_names = [target_plugin]
    else:
        plugin_names = [p["name"] for p in mp_plugins]

    if not plugin_names:
        print("チェック対象のプラグインがありません。")
        sys.exit(0)

    # チェック実行
    total_ok = 0
    total_ng = 0
    total_warn = 0

    for name in plugin_names:
        ctx = build_context(repo_root, name, mp_plugins)
        results = check_plugin(ctx)

        print(f"\n## {name}\n")
        for r in results:
            if r.status == Status.OK:
                print(f"  OK: {r.message}")
                total_ok += 1
            elif r.status == Status.NG:
                print(f"  NG: {r.message}")
                if r.fix:
                    print(f"      → {r.fix}")
                total_ng += 1
            elif r.status == Status.WARN:
                print(f"  WARN: {r.message}")
                total_warn += 1

    print(f"\n---\n合計: {total_ok} OK / {total_ng} NG / {total_warn} WARN")

    if total_ng > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
