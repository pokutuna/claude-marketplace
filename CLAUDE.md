# Claude Marketplace

A marketplace repository hosting multiple Claude Code plugins.

## Development

- Plugin guide: `docs/PLUGIN_GUIDE.md`
- Skills guide: `docs/The-Complete-Guide-to-Building-Skills-for-Claude.md`
  - If this file is missing, convert https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf to Markdown faithfully and place it there
- Skill format spec: https://agentskills.io/specification
  - `SKILL.md` frontmatter is defined there. `compatibility` is a top-level field;
    `metadata` holds only properties the spec does not define
- Checklist: `docs/CHECKLIST.md`

## Codex Support

Plugins that work outside Claude Code also carry a `<plugin>/.codex-plugin/plugin.json`
so the OpenAI Codex CLI can load them. Codex reads that manifest and shares the same
`skills/` directory, so skills are never duplicated or forked for it.

- Generate the manifest with `scripts/gen-codex-manifest.py [plugin ...]`. It derives the
  shared fields from `.claude-plugin/plugin.json` and takes the Codex-only display metadata
  (`interface.*`, which has no Claude equivalent) from `scripts/codex-interface.json`.
  Add a block there first — the script fails on a plugin it does not know.
- Leave `${CLAUDE_PLUGIN_ROOT}` in SKILL.md as-is. Codex lists each SKILL.md by absolute
  path in its prompt, so the model resolves the placeholder against the directory it read
  the skill from. Skills need no Codex-specific rewriting.
- Skip plugins whose value is a Claude Code mechanism Codex lacks: hooks-driven plugins,
  and anything depending on `CLAUDE_SESSION_ID` or `.claude/settings.json`. Codex's
  validator rejects a `hooks` field outright.
- `.agents/plugins/marketplace.json` is the Codex marketplace. Keep its entries in sync
  with the plugins that have a `.codex-plugin/`.
- Which plugins are actually installed into Codex is a local choice, not a repo one — it
  lives in `dotfiles/codex/sync-plugins.sh`.

## Commit Guidelines

Follow `docs/CHECKLIST.md` when adding or modifying plugins.
