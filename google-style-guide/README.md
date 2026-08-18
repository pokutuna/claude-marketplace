# google-style-guide

Skills for writing and fixing developer documentation following the [Google developer documentation style guide](https://developers.google.com/style).

## Skills

| Skill | For |
|-------|-----|
| `style-en` | English documentation — the guide's rules condensed into a core rule set plus 13 on-demand reference files |
| `style-ja` | Japanese documentation — the guide's language-neutral rules plus Japanese wording conventions (半角英数, 和欧間スペース, 長音表記, etc.) |

Both skills activate when you ask Claude to write, fix, or review developer docs (READMEs, guides, tutorials, API references) or mention the Google style guide. `style-ja` shares the detailed reference files with `style-en`.

## What the skills do

- Fix or write documentation applying the guide's frequent rules without fetching anything; detailed specs (punctuation, procedures, placeholders, UI elements, word list, ...) are read on demand from `skills/style-en/references/`.
- Cite the rule slug when asked why a change was made; origin pages derive from `https://developers.google.com/style/<slug>`.
- For words not covered locally, fetch the origin word-list page rather than guessing.
- Rules scoped to Android/Cloud/Workspace docs are applied only when the document belongs to that product, and confirmed with you when unclear.

## Scope and limitations

- The reference files are a curated condensation, not an exhaustive mirror. The word list covers the general usage principles plus ~90 frequently needed entries out of ~730 on the origin page; uncovered words are checked against the origin at use time.
- The content was derived from a crawl of the style guide on 2026-08-18. The origin may have changed since.
- The local word-list source was a partial mirror; a few origin entries may be missing from the local copy.

## Attribution and license

The reference files condense and quote content from the [Google developer documentation style guide](https://developers.google.com/style), © Google, licensed under the [Creative Commons Attribution 4.0 License](https://creativecommons.org/licenses/by/4.0/). Code samples quoted from the guide are licensed under the [Apache 2.0 License](https://www.apache.org/licenses/LICENSE-2.0). This plugin is not affiliated with or endorsed by Google.
