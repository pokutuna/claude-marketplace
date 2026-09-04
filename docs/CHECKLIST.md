# Plugin Development Checklist

Checklist for adding or updating plugins.

## New Plugin

- [ ] Create `<plugin-name>/.claude-plugin/plugin.json`
  - name, version, description, author, keywords
- [ ] Create `<plugin-name>/README.md`
- [ ] Add entry to `.claude-plugin/marketplace.json` `plugins` array
  - name, description, source, homepage
- [ ] Implement Skills/Commands/Agents/Hooks
- [ ] Decide whether the plugin should also run under Codex (see `Codex Support` in `CLAUDE.md`)
  - If yes: add a block to `scripts/codex-interface.json`, run `scripts/gen-codex-manifest.py <name>`,
    and add an entry to `.agents/plugins/marketplace.json`
  - Skip it for hooks-driven plugins and anything needing `CLAUDE_SESSION_ID` or `.claude/settings.json`

## Skill

- [ ] Create `skills/<skill-name>/SKILL.md`
  - frontmatter: name, description (both required). Add `compatibility` at the top level
    only when the skill needs specific tools or an environment; most skills do not
  - `metadata` is for properties the Agent Skills spec does not define. Do not put
    `compatibility` under it, and do not add `author` (the plugin manifest already carries it)
  - Do NOT add `version` to SKILL.md. Versioning is managed only in `plugin.json` (Claude Code resolves the plugin version from `plugin.json` → marketplace entry → git SHA; SKILL.md `version` is never used for update detection)
  - Include trigger words in description
- [ ] Reference scripts with `${CLAUDE_PLUGIN_ROOT}`
- [ ] Add usage examples (Examples section)

## Version Update

- [ ] Increment `version` in `plugin.json` (the only place versions are tracked)
  - Marketplace is cached; changes won't reflect without version bump
  - Skills do not carry their own version — bump the plugin instead
- [ ] Adding or regenerating `.codex-plugin/plugin.json` alone needs no bump
  - It does not change what Claude Code loads, so the marketplace cache is unaffected
  - But when a bump happens for any other reason, re-run `scripts/gen-codex-manifest.py <name>`
    so `.codex-plugin/plugin.json` carries the same version

## Before Commit

- [ ] Increment `version` in `plugin.json` if plugin files changed
- [ ] Verify entry added/updated in `marketplace.json`
- [ ] Verify homepage URL is correct (`claude-plugins` not `claude-marketplace`)
- [ ] Create or update `<plugin-name>/README.md`
- [ ] Add link to plugin directory (not README) in root `README.md` if new plugin added
- [ ] Verify `.gitignore` excludes unwanted files
- [ ] If the plugin has a `.codex-plugin/`, verify its `version` matches `.claude-plugin/plugin.json`
  and that `.agents/plugins/marketplace.json` lists it
