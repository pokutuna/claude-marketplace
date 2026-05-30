# Plugin Development Checklist

Checklist for adding or updating plugins.

## New Plugin

- [ ] Create `<plugin-name>/.claude-plugin/plugin.json`
  - name, version, description, author, keywords
- [ ] Create `<plugin-name>/README.md`
- [ ] Add entry to `.claude-plugin/marketplace.json` `plugins` array
  - name, description, source, homepage
- [ ] Implement Skills/Commands/Agents/Hooks

## Skill

- [ ] Create `skills/<skill-name>/SKILL.md`
  - frontmatter: name, description, metadata (author, compatibility)
  - Do NOT add `version` to SKILL.md. Versioning is managed only in `plugin.json` (Claude Code resolves the plugin version from `plugin.json` → marketplace entry → git SHA; SKILL.md `version` is never used for update detection)
  - Include trigger words in description
- [ ] Reference scripts with `${CLAUDE_PLUGIN_ROOT}`
- [ ] Add usage examples (Examples section)

## Version Update

- [ ] Increment `version` in `plugin.json` (the only place versions are tracked)
  - Marketplace is cached; changes won't reflect without version bump
  - Skills do not carry their own version — bump the plugin instead

## Before Commit

- [ ] Increment `version` in `plugin.json` if plugin files changed
- [ ] Verify entry added/updated in `marketplace.json`
- [ ] Verify homepage URL is correct (`claude-plugins` not `claude-marketplace`)
- [ ] Create or update `<plugin-name>/README.md`
- [ ] Add link to plugin directory (not README) in root `README.md` if new plugin added
- [ ] Verify `.gitignore` excludes unwanted files
